//
//  GeminiService.swift
//  GroundTruth
//  Created by Aryan Cyrus on 25/9/2026.

import Foundation
import CoreLocation
import FirebaseAILogic

/// Builds a Gemini `GenerativeModel` grounded in one project's details via a
/// system instruction, so every reply in that project's chat is already aware
/// of its status, roadmap, notes, cost estimate, and relevant regulatory text.
enum GeminiService {
    private static let modelName = "gemini-3.1-flash-lite"

    static func chatModel(for project: Project) async -> GenerativeModel {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        return ai.generativeModel(
            modelName: modelName,
            systemInstruction: ModelContent(role: "system", parts: await systemInstruction(for: project))
        )
    }

    private static func systemInstruction(for project: Project) async -> String {
        var lines = [
            instructionsPreamble(),
            "",
            "PROJECT DETAILS",
            "Name: \(project.name)",
            "Status: \(project.status.rawValue)",
            "Address: \(project.address)",
            "Description: \(project.projectDescription)",
            "Progress: \(project.tasksCompleted) of \(project.totalTasks) roadmap steps complete (\(Int(project.progress * 100))%)"
        ]

        if !project.tasks.isEmpty {
            lines.append("")
            lines.append("Roadmap steps:")
            lines += project.tasks.map { "- [\($0.isCompleted ? "x" : " ")] \($0.title)" }
        }

        if !project.notes.isEmpty {
            lines.append("")
            lines.append("Notes:")
            lines += project.notes.map { "- \($0.text)" }
        }

        if !project.documents.isEmpty {
            lines.append("")
            lines.append("Uploaded documents (names only, contents not available to you):")
            lines += project.documents.map { "- \($0.fileName)" }
        }

        switch CostEstimatorService().estimate(for: project.costEstimateInputs) {
        case .available(let low, let high):
            lines.append("")
            lines.append("Estimated cost of works: $\(Int(low)) - $\(Int(high)) (model estimate, +/-30%, not a quote).")
        case .unavailable:
            break
        }

        if let practiceNote = RegulatoryExerptService.buildingPracticeNoteText() {
            lines.append("")
            lines.append("BUILDING PRACTICE NOTE - When is a building permit required (source: Victorian Building Authority, current 20 Dec 2023)")
            lines.append(practiceNote)
        }

        if let planningBlock = await planningSchemeBlock(for: project) {
            lines.append("")
            lines.append(planningBlock)
        }

        return lines.joined(separator: "\n")
    }

    private static func planningSchemeBlock(for project: Project) async -> String? {
        guard let coordinate = await resolveCoordinate(for: project.address) else { return nil }
        guard let info = try? await VicmapPlanningService().fetchPlanningInfo(at: coordinate) else { return nil }
        guard let fullText = RegulatoryExerptService.planningSchemeFullText() else { return nil }

        let excerpts = RegulatoryExerptService.planningSchemeExcerpts(
            zoneCode: info.zoneCode,
            overlayCodes: info.overlayCodes,
            fullText: fullText
        )
        guard !excerpts.isEmpty else { return nil }

        var block = ["PLANNING SCHEME EXCERPT(S) - Cardinia Planning Scheme (clause(s) relevant to this property's zone/overlay)"]
        block += excerpts
        return block.joined(separator: "\n\n")
    }

    private static func resolveCoordinate(for address: String) async -> CLLocationCoordinate2D? {
        guard !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let placemarks = try? await CLGeocoder().geocodeAddressString(address)
        return placemarks?.first?.location?.coordinate
    }

    private static func instructionsPreamble() -> String {
        guard
            let url = Bundle.main.url(forResource: "AIInstructions", withExtension: "md"),
            let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            return "You are a helpful assistant embedded in GroundTruth, a home renovation and construction planning app. Be concise and practical. If the user asks about something not covered by these details, say so rather than guessing."
        }
        return text
    }
}
