//
//  ProjectStore.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import Foundation
import FirebaseFirestore
internal import Combine

@MainActor
final class ProjectStore: ObservableObject{
    @Published private(set) var projects: [Project] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let database: Firestore;
    private var listener: ListenerRegistration?
    
    init(database: Firestore = .firestore()){
        self.database = database
    }
    
    func startListening(){
        guard listener == nil else {return}
        isLoading = true
        
        listener = database.collection(Project.collectionName)
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
        isLoading = false
        projects = []
    }
    
    func clearError(){
        errorMessage = nil
    }
    
    func createProject(name: String, projectDescription: String, address: String, status: ProjectStatus, progress: Double, tasksCompleted: Int, totalTasks: Int) async throws {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedProjDesc = projectDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        //input validation
        guard !cleanedName.isEmpty, !cleanedProjDesc.isEmpty else {
            throw AppError.invalidForm("Please enter a name and description.")
        }
        
        guard cleanedName.count <= 80 else{
            throw AppError.invalidForm("Project name must be 80 characters or fewer")
        }
        
        guard cleanedProjDesc.count <= 600 else{
            throw AppError.invalidForm("Project description must be 600 characters or fewer")
        }
        
        //initialising Project Object
        let project = Project(name: name, projectDescription: projectDescription, address: address, status: status, progress: progress, tasksCompleted: tasksCompleted, totalTasks: totalTasks)
        
        let data = try Firestore.Encoder().encode(project)
        let reference  = database.collection(Project.collectionName).document()
        try await reference.setData(data)
        
         
    }
}
