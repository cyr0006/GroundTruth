//
//  ProjectChatView.swift
//  GroundTruth
//

import SwiftUI

struct ProjectChatView: View {
    let project: Project

    @StateObject private var viewModel: ProjectChatViewModel
    @State private var draft = ""
    @FocusState private var isInputFocused: Bool

    init(project: Project) {
        self.project = project
        _viewModel = StateObject(wrappedValue: ProjectChatViewModel(project: project))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if viewModel.messages.isEmpty {
                            Text("Ask anything about \(project.name) — its status, roadmap, address, or notes.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .padding(.top, 40)
                        }

                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }

                        if viewModel.isSending {
                            HStack(spacing: 6) {
                                ProgressView()
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .id("typing-indicator")
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.isSending) { _, _ in
                    scrollToBottom(proxy)
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $draft, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .lineLimit(1...4)

                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
            }
            .padding()
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: errorIsPresented) {
            Button("Ok", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "Please try again.")
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(get: { viewModel.errorMessage != nil }, set: { if !$0 { viewModel.errorMessage = nil } })
    }

    private func send() {
        let text = draft
        draft = ""
        viewModel.send(text)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if viewModel.isSending {
                proxy.scrollTo("typing-indicator", anchor: .bottom)
            } else if let last = viewModel.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }

            Text(formatted(message.text))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    message.role == .user ? Color.accentColor : Color(.systemGray5),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .foregroundStyle(message.role == .user ? Color.white : Color.primary)

            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private func formatted(_ text: String) -> AttributedString {
        (try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(text)
    }
}

#Preview {
    NavigationStack {
        ProjectChatView(project: Project.sampleProjects[0])
    }
}
