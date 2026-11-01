//
//  ProjectComplianceClassifierService.swift
//  GroundTruth
//

import Foundation
import CoreLocation
import FirebaseAILogic

/// Decides, in one combined Gemini call, whether a project likely needs a planning permit
/// (and which real fee class - `PlanningPermitFeeClass`), a building permit, and any of the
/// council-approval checklist items (`CouncilApprovalType`) - via a dedicated model call,
/// separate from the chat. One call rather than three: all three judgments need the same
/// zone/overlay/planning-scheme grounding assembled first, so building that three times for
/// three isolated calls would triple the work for no benefit, and risks the three answers
/// quietly contradicting each other.
///
/// The AI only ever picks a likelihood tier and (for planning permit) a class id - it never
/// states a dollar figure itself, so every number eventually shown comes from the hardcoded
/// fee schedules, never from the model's memory.
///
/// Deliberately a stronger model than the chat's gemini-3.1-flash-lite: this is a one-shot
/// structured decision where getting the classification right matters far more than shaving
/// latency or cost.
enum ProjectComplianceClassifierService {
    // Stronger tier than the chat model - verify this exact name is available to this
    // Firebase project on first run; swap if it 404s.
    private static let modelName = "gemini-3.1-flash"

    static func assess(project: Project) async -> ProjectComplianceAssessment? {
        guard let inputs = project.costEstimateInputs else { return nil }

        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(
            modelName: modelName,
            generationConfig: GenerationConfig(responseMIMEType: "application/json", responseSchema: responseSchema)
        )

        let prompt = await buildPrompt(for: project, inputs: inputs)

        guard let response = try? await model.generateContent(prompt),
              let text = response.text,
              let data = text.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(RawAssessment.self, from: data)
        else { return nil }

        return ProjectComplianceAssessment(
            planningPermit: PlanningPermitAssessment(
                likelihood: decoded.planningPermit.likelihood,
                feeClass: decoded.planningPermit.feeClass == "none" ? nil : PlanningPermitFeeClass(rawValue: decoded.planningPermit.feeClass),
                reasoning: decoded.planningPermit.reasoning
            ),
            buildingPermit: BuildingPermitAssessment(
                likelihood: decoded.buildingPermit.likelihood,
                reasoning: decoded.buildingPermit.reasoning
            ),
            councilApprovals: decoded.councilApprovals.compactMap { raw in
                guard let type = CouncilApprovalType(rawValue: raw.type) else { return nil }
                return CouncilApprovalAssessment(type: type, likelihood: raw.likelihood, reasoning: raw.reasoning)
            },
            assessedAt: Date()
        )
    }

    // MARK: - Wire format

    private struct RawPlanningPermit: Codable {
        var likelihood: PermitLikelihood
        var feeClass: String
        var reasoning: String
    }

    private struct RawBuildingPermit: Codable {
        var likelihood: PermitLikelihood
        var reasoning: String
    }

    private struct RawCouncilApproval: Codable {
        var type: String
        var likelihood: PermitLikelihood
        var reasoning: String
    }

    private struct RawAssessment: Codable {
        var planningPermit: RawPlanningPermit
        var buildingPermit: RawBuildingPermit
        var councilApprovals: [RawCouncilApproval]
    }

    // MARK: - Schema

    private static var responseSchema: Schema {
        let likelihoodValues = PermitLikelihood.allCases.map(\.rawValue)

        return Schema.object(
            properties: [
                "planningPermit": .object(
                    properties: [
                        "likelihood": .enumeration(values: likelihoodValues, description: "Likelihood a planning permit is required."),
                        "feeClass": .enumeration(
                            values: PlanningPermitFeeClass.allCases.map(\.rawValue) + ["none"],
                            description: "The single best-matching fee class id, or \"none\" if a fee class doesn't apply."
                        ),
                        "reasoning": .string(description: "One to two sentences, referencing the zone/overlay/clause if relevant.")
                    ]
                ),
                "buildingPermit": .object(
                    properties: [
                        "likelihood": .enumeration(values: likelihoodValues, description: "Likelihood a building permit is required."),
                        "reasoning": .string(description: "One to two sentences, referencing the Building Practice Note if relevant.")
                    ]
                ),
                "councilApprovals": .array(
                    items: .object(
                        properties: [
                            "type": .enumeration(values: CouncilApprovalType.allCases.map(\.rawValue), description: "Which council approval this entry is for."),
                            "likelihood": .enumeration(values: likelihoodValues, description: "Likelihood this specific approval is needed."),
                            "reasoning": .string(description: "One sentence explaining the decision for this specific approval.")
                        ]
                    ),
                    description: "Exactly one entry for each of the \(CouncilApprovalType.allCases.count) council approval types listed in the prompt - never omit one."
                )
            ]
        )
    }

    // MARK: - Prompt

    // Deliberately reuses the exact same zone/overlay + planning-scheme-excerpt resolution
    // GeminiService uses for the chat (VicmapPlanningService + RegulatoryExerptService), plus
    // the Building Practice Note already bundled for the chat - this call gets the same
    // grounding, not a stripped-down version of it, assembled once for all three judgments.
    private static func buildPrompt(for project: Project, inputs: CostEstimateInputs) async -> String {
        var lines = [
            """
            You are assessing a proposed Victorian residential project against three things: \
            whether it needs a planning permit, whether it needs a building permit, and which \
            of a fixed list of council approvals it might need. Respond strictly via the \
            provided JSON schema. Never state a dollar figure anywhere - only likelihood tiers \
            and (for planning permit) a fee class id; the app looks up the real fee itself. Use \
            the full range of likelihood tiers rather than defaulting to the extremes - most \
            real projects sit somewhere in the middle, not a confident "required" or "not \
            required".
            """,
            "",
            "PROJECT",
            "Type: \(inputs.projectType)"
        ]

        if let subtype = inputs.workSubtype {
            lines.append("Subtype: \(subtype)")
        }
        if inputs.floorAreaSqm > 0 {
            lines.append("Floor area: \(Int(inputs.floorAreaSqm)) sqm")
        }
        lines.append("Address: \(project.address)")
        lines.append("Description: \(project.projectDescription)")

        if let coordinate = await resolveCoordinate(for: project.address),
           let info = try? await VicmapPlanningService().fetchPlanningInfo(at: coordinate) {
            lines.append("Zone code: \(info.zoneCode ?? "unknown")")
            lines.append("Overlay codes: \(info.overlayCodes.isEmpty ? "none" : info.overlayCodes.joined(separator: ", "))")

            if let fullText = RegulatoryExerptService.planningSchemeFullText() {
                let excerpts = RegulatoryExerptService.planningSchemeExcerpts(
                    zoneCode: info.zoneCode,
                    overlayCodes: info.overlayCodes,
                    fullText: fullText
                )
                if !excerpts.isEmpty {
                    lines.append("")
                    lines.append("RELEVANT PLANNING SCHEME CLAUSE(S)")
                    lines += excerpts
                }
            }
        }

        if let practiceNote = RegulatoryExerptService.buildingPracticeNoteText() {
            lines.append("")
            lines.append("BUILDING PRACTICE NOTE - When is a building permit required (source: Victorian Building Authority)")
            lines.append(practiceNote)
        }

        lines.append("")
        lines.append("PLANNING PERMIT FEE CLASSES (choose exactly one feeClass id, or \"none\")")
        lines += PlanningPermitFeeClass.allCases.map { "- \($0.rawValue): \($0.displayName)" }
        lines.append("""
        Guidance: VicSmart covers minor, straightforward works (small outbuildings, fences, \
        minor extensions/alterations meeting specific size and setback criteria) with a single \
        flat fee. "Single dwelling" classes apply to building or extending one dwelling, banded \
        by estimated cost of development. "Other development" classes cover larger or \
        multi-unit works. Many minor works are also entirely exempt from needing a planning \
        permit at all - if that plausibly applies, prefer a low likelihood and feeClass "none" \
        rather than guessing a class that doesn't fit.
        """)

        lines.append("")
        lines.append("COUNCIL APPROVALS (assess every one of these \(CouncilApprovalType.allCases.count) - include all of them in your response, in this order)")
        lines += CouncilApprovalType.allCases.map { "- \($0.rawValue) (\($0.displayName)): \($0.guidance)" }

        return lines.joined(separator: "\n")
    }

    private static func resolveCoordinate(for address: String) async -> CLLocationCoordinate2D? {
        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let placemarks = try? await CLGeocoder().geocodeAddressString(address)
        return placemarks?.first?.location?.coordinate
    }
}
