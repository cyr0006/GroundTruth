//
//  GeminiService.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 25/9/2026.
//

import Foundation
import FirebaseAI

/// Builds a Gemini `GenerativeModel` grounded in one project's details via a
/// system instruction, so every reply in that project's chat is already aware
/// of its status, roadmap, notes, and documents without the user repeating them.
enum GeminiService {
    private static let modelName = "gemini-2.5-flash"

    static func chatModel(for project: Project) -> GenerativeModel {
        let ai = FirebaseAI.firebaseAI(backend: .googleAI())
        return ai.generativeModel(
            modelName: modelName,
            systemInstruction: ModelContent(role: "system", parts: systemInstruction(for: project))
        )
    }

    private static func systemInstruction(for project: Project) -> String {
        var lines = [
            "You are a helpful assistant embedded in GroundTruth, a home renovation and construction planning app.",
            "You are helping the user with one specific project. Use the project details below to ground your answers.",
            "Be concise and practical. If the user asks about something not covered by these details, say so rather than guessing.",
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

        return lines.joined(separator: "\n")
    }
}



