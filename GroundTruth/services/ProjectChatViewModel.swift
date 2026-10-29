//
//  ProjectChatViewModel.swift
//  GroundTruth
//  Created by Aryan Cyrus  on 29/10/2026.
//


import Foundation

@MainActor
final class ProjectChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage]
    @Published private(set) var isSending = false
    @Published private(set) var isPreparing = true
    @Published var errorMessage: String?

    private var chat: Chat?
    private let project: Project
    private let projectStore: ProjectStore

    init(project: Project, projectStore: ProjectStore) {
        self.project = project
        self.projectStore = projectStore
        self.messages = project.chatMessages

        Task {
            chat = await GeminiService.chatModel(for: project).startChat()
            isPreparing = false
        }
    }

    func send(_ text: String) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, !isSending, !isPreparing, let chat else { return }

        messages.append(ChatMessage(role: .user, text: cleaned))
        isSending = true
        persistMessages()

        Task {
            defer { isSending = false }
            do {
                let response = try await chat.sendMessage(cleaned)
                let reply = response.text ?? "I didn't get a response for that — try rephrasing."
                messages.append(ChatMessage(role: .assistant, text: reply))
                persistMessages()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func persistMessages() {
        let snapshot = messages
        Task {
            try? await projectStore.setChatMessages(snapshot, for: project)
        }
    }
}