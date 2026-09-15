//
//  Project.swift
//  GroundTruth
//
//  Basic model used to drive placeholder UI before SwiftData persistence
//  is wired up.
//

import Foundation

enum ProjectStatus: String, CaseIterable {
    case planning = "Planning"
    case permits = "Permits"
    case construction = "Construction"
    case complete = "Complete"

    var tint: String {
        switch self {
        case .planning: return "blue"
        case .permits: return "orange"
        case .construction: return "purple"
        case .complete: return "green"
        }
    }
}

struct Project: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var projectDescription: String
    var address: String
    var status: ProjectStatus
    var progress: Double // 0.0 - 1.0
    var tasksCompleted: Int
    var totalTasks: Int
}

extension Project {
    static let sampleProjects: [Project] = [
        Project(
            name: "Backyard Deck",
            projectDescription: "New timber deck with pergola off the back of the house.",
            address: "12 Wattle Street, Camberwell VIC 3124",
            status: .permits,
            progress: 0.4,
            tasksCompleted: 4,
            totalTasks: 10
        ),
        Project(
            name: "Granny Flat",
            projectDescription: "Secondary dwelling in the rear yard for extended family.",
            address: "8 Riverside Ave, Hawthorn VIC 3122",
            status: .planning,
            progress: 0.15,
            tasksCompleted: 2,
            totalTasks: 14
        ),
        Project(
            name: "Kitchen Renovation",
            projectDescription: "Internal renovation, no structural changes.",
            address: "45 High Street, Kew VIC 3101",
            status: .construction,
            progress: 0.75,
            tasksCompleted: 9,
            totalTasks: 12
        )
    ]
}
