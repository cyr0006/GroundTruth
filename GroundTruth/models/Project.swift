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

/// Metadata for a file uploaded to Firebase Storage for a project. The file bytes
/// themselves live in Storage at `storagePath` — this struct is just what's stored
/// on the Firestore project document.
struct ProjectDocument: Identifiable, Hashable, Codable {
    var id: String
    var fileName: String
    var storagePath: String
    var downloadURL: String
    var uploadedAt: Date
    var fileSizeBytes: Int64
}

struct ProjectNote: Identifiable, Hashable, Codable {
    var id: String
    var text: String
    var createdAt: Date
}

struct ProjectTask: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var isCompleted: Bool
}

/// A file picked on-device but not yet uploaded — the input to `ProjectStore`'s
/// upload methods. Not itself stored anywhere.
struct PendingProjectDocument: Identifiable {
    let id = UUID()
    let fileName: String
    let data: Data
}

struct Project: Identifiable,Hashable, Codable {
    static let collectionName = "projects"

    @DocumentID private var projID: String?
    var ownerId: String
    var name: String
    var projectDescription: String
    var address: String
    var status: ProjectStatus
    var documents: [ProjectDocument]
    var notes: [ProjectNote]
    var tasks: [ProjectTask]

    var id: String?{
        projID ?? ""
    }

    // Derived from `tasks` rather than stored, so the roadmap checklist and the
    // progress bar can never drift out of sync with each other.
    var totalTasks: Int { tasks.count }
    var tasksCompleted: Int { tasks.filter(\.isCompleted).count }
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasksCompleted) / Double(totalTasks)
    }

    init(projID: String? = nil, ownerId: String, name: String, projectDescription: String, address: String, status: ProjectStatus, documents: [ProjectDocument] = [], notes: [ProjectNote] = [], tasks: [ProjectTask] = []) {
        self.projID = projID
        self.ownerId = ownerId
        self.name = name
        self.projectDescription = projectDescription
        self.address = address
        self.status = status
        self.documents = documents
        self.notes = notes
        self.tasks = tasks
    }
}

extension Project {
    /// Builds `count` sample tasks with the first `completed` marked done.
    private static func sampleTasks(completed: Int, count: Int) -> [ProjectTask] {
        (0..<count).map { index in
            ProjectTask(id: "sample-\(index)", title: "Sample step \(index + 1)", isCompleted: index < completed)
        }
    }

    static let sampleProjects: [Project] = [
        Project(
            ownerId: "preview-user",
            name: "Backyard Deck",
            projectDescription: "New timber deck with pergola off the back of the house.",
            address: "12 Wattle Street, Camberwell VIC 3124",
            status: .permits,
            tasks: sampleTasks(completed: 4, count: 10)
        ),
        Project(
            ownerId: "preview-user",
            name: "Granny Flat",
            projectDescription: "Secondary dwelling in the rear yard for extended family.",
            address: "8 Riverside Ave, Hawthorn VIC 3122",
            status: .planning,
            tasks: sampleTasks(completed: 2, count: 14)
        ),
        Project(
            ownerId: "preview-user",
            name: "Kitchen Renovation",
            projectDescription: "Internal renovation, no structural changes.",
            address: "21 Emerald Lake Rd, Emerald VIC 3782",
            status: .construction,
            tasks: sampleTasks(completed: 9, count: 12)
        )
    ]
}
