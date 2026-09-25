//
//  ProjectChatViewModel.swift
//  GroundTruth
//

import Foundation
import FirebaseAILogic
internal import Combine

@MainActor
final class ProjectChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    private let chat: Chat

    init(project: Project) {
        chat = GeminiService.chatModel(for: project).startChat()
    }

    func send(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !isSending else { return }

        messages.append(ChatMessage(role: .user, text: cleaned))
        isSending = true

        Task {
            defer { isSending = false }
            do {
                let response = try await chat.sendMessage(cleaned)
                let reply = response.text ?? "I didn't get a response for that — try rephrasing."
                messages.append(ChatMessage(role: .assistant, text: reply))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
