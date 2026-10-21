//
//  ChatMessage.swift
//  GroundTruth
//

import Foundation

/// One turn in an AI chat. Persisted on the owning `Project` document so a
/// conversation survives leaving the chat screen or relaunching the app.
struct ChatMessage: Identifiable, Hashable, Codable {
    enum Role: String, Hashable, Codable {
        case user
        case assistant
    }

    var id: String = UUID().uuidString
    let role: Role
    let text: String
    var sentAt: Date = Date()
}
