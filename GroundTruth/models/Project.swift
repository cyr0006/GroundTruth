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
/// themselves live in Storage at `storagePath`this struct is just what's stored
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
    var dueDate: Date? = nil
    var description: String = ""
    /// Which roadmap phase this step belongs to — drives `Project.effectiveStatus`.
    var phase: ProjectStatus = .planning

    init(id: String, title: String, isCompleted: Bool, dueDate: Date? = nil, description: String = "", phase: ProjectStatus = .planning) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.description = description
        self.phase = phase
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, dueDate, description, phase
    }

    // Custom decode so tasks saved before `description`/`phase` existed (missing
    // those keys in Firestore) still decode instead of silently dropping the
    // whole project — a synthesized Decodable would require every key present.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        phase = try container.decodeIfPresent(ProjectStatus.self, forKey: .phase) ?? .planning
    }
}

struct CostEstimateInputs: Hashable, Codable{
    var floorAreaSqm: Double
    var projectType: String
    var workSubtype: String? = nil
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
    var chatMessages: [ChatMessage]
    var costEstimateInputs: CostEstimateInputs? = nil
    /// Cached result of `PlanningPermitClassifierService`, keyed to the current
    /// `costEstimateInputs` - nil means "not yet classified for the current scope."
    var planningPermitClassification: PlanningPermitClassification? = nil

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

    // The displayed status, derived from the roadmap rather than the stored
    // `status` field, so it can't drift out of sync with the checklist. You're
    // "stuck" in the earliest phase that still has an incomplete step; once every
    // step is done, the project reads as Complete. `status` itself still matters
    // as the starting point before any steps have a phase assigned to disagree with.
    var effectiveStatus: ProjectStatus {
        guard !tasks.isEmpty else { return status }
        let incompletePhases = Set(tasks.filter { !$0.isCompleted }.map(\.phase))
        return ProjectStatus.allCases.first { incompletePhases.contains($0) } ?? .complete
    }

    init(projID: String? = nil, ownerId: String, name: String, projectDescription: String, address: String, status: ProjectStatus, documents: [ProjectDocument] = [], notes: [ProjectNote] = [], tasks: [ProjectTask] = [], chatMessages: [ChatMessage] = [], costEstimateInputs: CostEstimateInputs? = nil) {
        self.projID = projID
        self.ownerId = ownerId
        self.name = name
        self.projectDescription = projectDescription
        self.address = address
        self.status = status
        self.documents = documents
        self.notes = notes
        self.tasks = tasks
        self.chatMessages = chatMessages
        self.costEstimateInputs = costEstimateInputs
    }
}

extension Project {
    /// Builds `count` sample tasks with the first `completed` marked done, all tagged
    /// with `phase` so `effectiveStatus` matches the sample project's intended status.
    private static func sampleTasks(completed: Int, count: Int, phase: ProjectStatus) -> [ProjectTask] {
        (0..<count).map { index in
            ProjectTask(id: "sample-\(index)", title: "Sample step \(index + 1)", isCompleted: index < completed, phase: phase)
        }
    }

    static let sampleProjects: [Project] = [
        Project(
            ownerId: "preview-user",
            name: "Backyard Deck",
            projectDescription: "New timber deck with pergola off the back of the house.",
            address: "12 Wattle Street, Camberwell VIC 3124",
            status: .permits,
            tasks: sampleTasks(completed: 4, count: 10, phase: .permits)
        ),
        Project(
            ownerId: "preview-user",
            name: "Granny Flat",
            projectDescription: "Secondary dwelling in the rear yard for extended family.",
            address: "8 Riverside Ave, Hawthorn VIC 3122",
            status: .planning,
            tasks: sampleTasks(completed: 2, count: 14, phase: .planning)
        ),
        Project(
            ownerId: "preview-user",
            name: "Kitchen Renovation",
            projectDescription: "Internal renovation, no structural changes.",
            address: "21 Emerald Lake Rd, Emerald VIC 3782",
            status: .construction,
            tasks: sampleTasks(completed: 9, count: 12, phase: .construction)
        )
    ]
}
