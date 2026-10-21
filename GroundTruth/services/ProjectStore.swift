//
//  ProjectStore.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
internal import Combine

@MainActor
final class ProjectStore: ObservableObject{
    @Published private(set) var projects: [Project] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let database: Firestore;
    private let storage: Storage
    private var listener: ListenerRegistration?
    private var currentUserId: String?

    init(database: Firestore = .firestore(), storage: Storage = .storage()){
        self.database = database
        self.storage = storage
    }

    /// Starts listening to just the signed-in user's projects. Call `stopListening()`
    /// first if the signed-in user changes (RootView already does this).
    func startListening(for userId: String){
        guard listener == nil else {return}
        currentUserId = userId
        isLoading = true

        listener = database.collection(Project.collectionName)
            .whereField("ownerId", isEqualTo: userId)
            .addSnapshotListener{ [weak self] snapshot, error in
                Task{ @MainActor in
                    guard let self else {return}
                    self.isLoading = false
                    
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    let documents = snapshot?.documents ?? []
                    let projects = documents
                        .compactMap {try? $0.data(as: Project.self)}
                        .sorted{
                            ($0.name) > ($1.name)
                        }
                    
                    #if DEBUG
                    if projects.count != documents.count{
                        print("ignored \(documents.count - projects.count) malformed project documents")
                    }
                    #endif
                    
                    self.projects = projects
                }
        }
    }
    
    func stopListening(){
        listener?.remove()
        listener = nil
        currentUserId = nil
        isLoading = false
        projects = []
    }

    func clearError(){
        errorMessage = nil
    }

    func setError(_ message: String){
        errorMessage = message
    }

    func createProject(name: String, projectDescription: String, address: String, status: ProjectStatus = .planning, noteTexts: [String] = [], pendingDocuments: [PendingProjectDocument] = [], taskTitles: [String] = []) async throws {
        guard let ownerId = currentUserId else {
            throw AppError.notSignedIn
        }

        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedProjDesc = projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)

        //input validation
        guard !cleanedName.isEmpty, !cleanedProjDesc.isEmpty else {
            throw AppError.invalidForm("Please enter a name and description.")
        }

        guard !cleanedAddress.isEmpty else {
            throw AppError.invalidForm("Please enter an address.")
        }

        guard cleanedName.count <= 80 else{
            throw AppError.invalidForm("Project name must be 80 characters or fewer")
        }

        guard cleanedProjDesc.count <= 600 else{
            throw AppError.invalidForm("Project description must be 600 characters or fewer")
        }

        // The Firestore document ID is generated client-side so we can use it as the
        // Storage folder for any attached documents before the project document exists.
        let reference = database.collection(Project.collectionName).document()
        let projectId = reference.documentID

        let uploadedDocuments = try await upload(pendingDocuments, ownerId: ownerId, projectId: projectId)
        let notes = noteTexts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { ProjectNote(id: UUID().uuidString, text: $0, createdAt: Date()) }
        let tasks = taskTitles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { ProjectTask(id: UUID().uuidString, title: $0, isCompleted: false) }

        //initialising Project Object
        let project = Project(
            projID: projectId,
            ownerId: ownerId,
            name: cleanedName,
            projectDescription: cleanedProjDesc,
            address: cleanedAddress,
            status: status,
            documents: uploadedDocuments,
            notes: notes,
            tasks: tasks
        )

        let data = try Firestore.Encoder().encode(project)
        try await reference.setData(data)
    }

    func updateProject(_ project: Project, name: String, projectDescription: String, address: String, status: ProjectStatus) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedProjDesc = projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanedName.isEmpty, !cleanedProjDesc.isEmpty else {
            throw AppError.invalidForm("Please enter a name and description.")
        }

        guard !cleanedAddress.isEmpty else {
            throw AppError.invalidForm("Please enter an address.")
        }

        guard cleanedName.count <= 80 else {
            throw AppError.invalidForm("Project name must be 80 characters or fewer")
        }

        guard cleanedProjDesc.count <= 600 else {
            throw AppError.invalidForm("Project description must be 600 characters or fewer")
        }

        try await database.collection(Project.collectionName).document(projectId).updateData([
            "name": cleanedName,
            "projectDescription": cleanedProjDesc,
            "address": cleanedAddress,
            "status": status.rawValue
        ])
    }

    func addTask(title: String, dueDate: Date? = nil, to project: Project) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw AppError.invalidForm("Enter a step description.")
        }

        let newTask = ProjectTask(id: UUID().uuidString, title: cleaned, isCompleted: false, dueDate: dueDate)
        var updatedTasks = project.tasks
        updatedTasks.append(newTask)
        try await updateTasksField(updatedTasks, projectId: projectId)

        if let dueDate, await NotificationService.requestAuthorizationIfNeeded() {
            NotificationService.scheduleDueDateReminder(
                taskId: newTask.id,
                taskTitle: newTask.title,
                projectName: project.name,
                dueDate: dueDate
            )
        }
    }

    func setTaskCompleted(_ task: ProjectTask, isCompleted: Bool, in project: Project) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        var updatedTasks = project.tasks
        guard let index = updatedTasks.firstIndex(where: { $0.id == task.id }) else { return }
        updatedTasks[index].isCompleted = isCompleted
        try await updateTasksField(updatedTasks, projectId: projectId)

        if isCompleted {
            NotificationService.cancelReminder(taskId: task.id)
        }
    }

    func deleteTask(_ task: ProjectTask, from project: Project) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        NotificationService.cancelReminder(taskId: task.id)

        let updatedTasks = project.tasks.filter { $0.id != task.id }
        try await updateTasksField(updatedTasks, projectId: projectId)
    }

    private func updateTasksField(_ tasks: [ProjectTask], projectId: String) async throws {
        let encoded = try tasks.map { try Firestore.Encoder().encode($0) }
        try await database.collection(Project.collectionName).document(projectId)
            .updateData(["tasks": encoded])
    }

    func addDocument(_ pending: PendingProjectDocument, to project: Project) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        let uploaded = try await upload(pending, ownerId: project.ownerId, projectId: projectId)
        var updatedDocuments = project.documents
        updatedDocuments.append(uploaded)
        try await updateDocumentsField(updatedDocuments, projectId: projectId)
    }

    func deleteDocument(_ document: ProjectDocument, from project: Project) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        try await storage.reference(withPath: document.storagePath).delete()
        let updatedDocuments = project.documents.filter { $0.id != document.id }
        try await updateDocumentsField(updatedDocuments, projectId: projectId)
    }

    func addNote(text: String, to project: Project) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw AppError.invalidForm("Enter some note text.")
        }

        var updatedNotes = project.notes
        updatedNotes.append(ProjectNote(id: UUID().uuidString, text: cleaned, createdAt: Date()))
        try await updateNotesField(updatedNotes, projectId: projectId)
    }

    func deleteNote(_ note: ProjectNote, from project: Project) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        let updatedNotes = project.notes.filter { $0.id != note.id }
        try await updateNotesField(updatedNotes, projectId: projectId)
    }

    func setChatMessages(_ messages: [ChatMessage], for project: Project) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        let encoded = try messages.map { try Firestore.Encoder().encode($0) }
        try await database.collection(Project.collectionName).document(projectId)
            .updateData(["chatMessages": encoded])
    }

    func deleteProject(_ project: Project) async throws {
        guard let projectId = project.id, !projectId.isEmpty else {
            throw AppError.projectNotFound
        }

        for document in project.documents {
            try? await storage.reference(withPath: document.storagePath).delete()
        }

        try await database.collection(Project.collectionName).document(projectId).delete()
    }

    private func updateDocumentsField(_ documents: [ProjectDocument], projectId: String) async throws {
        let encoded = try documents.map { try Firestore.Encoder().encode($0) }
        try await database.collection(Project.collectionName).document(projectId)
            .updateData(["documents": encoded])
    }

    private func updateNotesField(_ notes: [ProjectNote], projectId: String) async throws {
        let encoded = try notes.map { try Firestore.Encoder().encode($0) }
        try await database.collection(Project.collectionName).document(projectId)
            .updateData(["notes": encoded])
    }

    private func upload(_ pendingDocuments: [PendingProjectDocument], ownerId: String, projectId: String) async throws -> [ProjectDocument] {
        var uploaded: [ProjectDocument] = []
        for pending in pendingDocuments {
            uploaded.append(try await upload(pending, ownerId: ownerId, projectId: projectId))
        }
        return uploaded
    }

    private func upload(_ pending: PendingProjectDocument, ownerId: String, projectId: String) async throws -> ProjectDocument {
        let docId = UUID().uuidString
        let storagePath = "projects/\(ownerId)/\(projectId)/documents/\(docId)-\(pending.fileName)"
        let storageRef = storage.reference(withPath: storagePath)

        _ = try await storageRef.putDataAsync(pending.data)
        let downloadURL = try await storageRef.downloadURL()

        return ProjectDocument(
            id: docId,
            fileName: pending.fileName,
            storagePath: storagePath,
            downloadURL: downloadURL.absoluteString,
            uploadedAt: Date(),
            fileSizeBytes: Int64(pending.data.count)
        )
    }
}
