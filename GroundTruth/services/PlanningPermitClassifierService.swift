//
//  PlanningPermitClassifierService.swift
//  GroundTruth
//

import Foundation
import CoreLocation
import FirebaseAILogic

/// Decides which real Victorian planning-permit fee class (`PlanningPermitFeeClass`) a
/// project's proposed works fall into, if any - via a dedicated Gemini call, separate from
/// the chat model. The AI only ever picks a class id from a fixed list; it never states a
/// dollar figure itself, so the number eventually shown always comes from
/// `PlanningPermitFeeClass.fee`, never from the model's memory.
///
/// Deliberately a stronger model than the chat's gemini-3.1-flash-lite: this is a one-shot
/// structured decision where getting the classification right matters far more than shaving
/// latency or cost.
enum PlanningPermitClassifierService {
    // Stronger tier than the chat model - verify this exact name is available to this
    // Firebase project on first run; swap if it 404s.
    private static let modelName = "gemini-3.1-flash"

    static func classify(project: Project) async -> PlanningPermitClassification? {
        guard let inputs = project.costEstimateInputs else { return nil }

        let schema = Schema.object(
            properties: [
                "requirement": .enumeration(
                    values: ["yes", "no", "uncertain"],
                    description: "Whether a planning permit is required for this project."
                ),
                "feeClass": .enumeration(
                    values: PlanningPermitFeeClass.allCases.map(\.rawValue) + ["none"],
                    description: "The single best-matching fee class id, or \"none\" if requirement is \"no\"."
                ),
                "reasoning": .string(
                    description: "One to two sentences explaining the decision, referencing the zone/overlay/clause if relevant."
                )
            ],
            requiredProperties: ["requirement", "feeClass", "reasoning"]
        )

        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        let model = ai.generativeModel(
            modelName: modelName,
            generationConfig: GenerationConfig(responseMIMEType: "application/json", responseSchema: schema)
        )

        let prompt = await buildPrompt(for: project, inputs: inputs)

        guard let response = try? await model.generateContent(prompt),
              let text = response.text,
              let data = text.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(RawClassification.self, from: data)
        else { return nil }

        let feeClass = decoded.feeClass == "none" ? nil : PlanningPermitFeeClass(rawValue: decoded.feeClass)

        return PlanningPermitClassification(
            requirement: decoded.requirement,
            feeClass: feeClass,
            reasoning: decoded.reasoning,
            classifiedAt: Date()
        )
    }

    private struct RawClassification: Codable {
        var requirement: PlanningPermitClassification.Requirement
        var feeClass: String
        var reasoning: String
    }

    // Deliberately reuses the exact same zone/overlay + planning-scheme-excerpt resolution
    // GeminiService uses for the chat (VicmapPlanningService + RegulatoryExerptService), so
    // this call sees the same grounding, not a stripped-down version of it.
    private static func buildPrompt(for project: Project, inputs: CostEstimateInputs) async -> String {
        var lines = [
            "You are classifying which Victorian planning permit fee class applies to a proposed residential project, if any. Respond strictly via the provided JSON schema - never state a dollar figure, only the class id.",
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

        lines.append("")
        lines.append("FEE CLASSES TO CHOOSE FROM (choose exactly one feeClass id, or \"none\" if requirement is \"no\")")
        lines += PlanningPermitFeeClass.allCases.map { "- \($0.rawValue): \($0.displayName)" }

        lines.append("")
        lines.append("""
        Guidance: Victoria's VicSmart stream covers minor, straightforward works (small \
        outbuildings, fences, minor extensions/alterations meeting specific size and setback \
        criteria) with a single flat fee. "Single dwelling" classes apply to building or \
        extending one dwelling, banded by estimated cost of development. "Other development" \
        classes cover larger or multi-unit works. Many minor works are also entirely exempt \
        from needing a planning permit at all - if that plausibly applies here, prefer \
        requirement "no" and feeClass "none" rather than guessing a class that doesn't fit.
        """)

        return lines.joined(separator: "\n")
    }

    private static func resolveCoordinate(for address: String) async -> CLLocationCoordinate2D? {
        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let placemarks = try? await CLGeocoder().geocodeAddressString(address)
        return placemarks?.first?.location?.coordinate
    }
}
