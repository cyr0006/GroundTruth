//
//  ChatMessage.swift
//  GroundTruth
//

import Foundation

/// One turn in an AI chat. Kept in memory only for the lifetime of the chat
/// screen — not persisted to Firestore.
struct ChatMessage: Identifiable, Equatable {
    enum Role: Equatable {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}
