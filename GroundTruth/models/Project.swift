//
//  Project.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import Foundation
import FirebaseFirestore

enum ProjectStatus: String, CaseIterable, Codable, Identifiable {
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
    
    var id: String {rawValue}
}

struct Project: Identifiable,Hashable, Codable {
    static let collectionName = "projects"

    @DocumentID private var projID: String?
    var ownerId: String
    var name: String
    var projectDescription: String
    var address: String
    var status: ProjectStatus
    var progress: Double // 0.0 - 1.0
    var tasksCompleted: Int
    var totalTasks: Int

    var id: String?{
        projID ?? ""
    }

    init(projID: String? = nil, ownerId: String, name: String, projectDescription: String, address: String, status: ProjectStatus, progress: Double, tasksCompleted: Int, totalTasks: Int) {
        self.projID = projID
        self.ownerId = ownerId
        self.name = name
        self.projectDescription = projectDescription
        self.address = address
        self.status = status
        self.progress = progress
        self.tasksCompleted = tasksCompleted
        self.totalTasks = totalTasks
    }
}

extension Project {
    static let sampleProjects: [Project] = [
        Project(
            ownerId: "preview-user",
            name: "Backyard Deck",
            projectDescription: "New timber deck with pergola off the back of the house.",
            address: "12 Wattle Street, Camberwell VIC 3124",
            status: .permits,
            progress: 0.4,
            tasksCompleted: 4,
            totalTasks: 10
        ),
        Project(
            ownerId: "preview-user",
            name: "Granny Flat",
            projectDescription: "Secondary dwelling in the rear yard for extended family.",
            address: "8 Riverside Ave, Hawthorn VIC 3122",
            status: .planning,
            progress: 0.15,
            tasksCompleted: 2,
            totalTasks: 14
        ),
        Project(
            ownerId: "preview-user",
            name: "Kitchen Renovation",
            projectDescription: "Internal renovation, no structural changes.",
            address: "21 Emerald Lake Rd, Emerald VIC 3782",
            status: .construction,
            progress: 0.75,
            tasksCompleted: 9,
            totalTasks: 12
        )
    ]
}
