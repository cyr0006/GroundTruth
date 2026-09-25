//
//  ProjectsView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProjectsView: View {
    @EnvironmentObject private var projectStore: ProjectStore
    @State private var isShowingNewProject = false

    var body: some View {
        NavigationStack {
            Group {
                if projectStore.isLoading && projectStore.projects.isEmpty {
                    ProgressView("Loading your projects...")
                } else if projectStore.projects.isEmpty {
                    ContentUnavailableView(
                        "No Projects Yet",
                        systemImage: "hammer",
                        description: Text("Create your first project to get a roadmap and checklist.")
                    )
                } else {
                    List {
                        ForEach(projectStore.projects) { project in
                            NavigationLink(value: project) {
                                ProjectRow(project: project)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Projects")
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(projectId: project.id ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingNewProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingNewProject) {
                NewProjectView()
            }
            .alert("Couldn't Load Projects", isPresented: projectErrorIsPresented) {
                Button("Ok", role: .cancel) { projectStore.clearError() }
            } message: {
                Text(projectStore.errorMessage ?? "Please try again.")
            }
        }
    }

    private var projectErrorIsPresented: Binding<Bool> {
        Binding(
            get: { projectStore.errorMessage != nil },
            set: { if !$0 { projectStore.clearError() } }
        )
    }
}

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(project.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: project.status)
            }

            Label(project.address, systemImage: "mappin.and.ellipse")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            ProgressView(value: project.progress)
                .tint(.accentColor)
        }
        .padding(.vertical, 4)
    }
}

private struct ProjectDetailView: View {
    let projectId: String

    @EnvironmentObject private var projectStore: ProjectStore
    @State private var isShowingDocumentPicker = false
    @State private var isUploadingDocument = false
    @State private var newNoteText = ""
    @State private var isAddingNote = false
    @State private var errorMessage: String?

    // Looked up live from the store (rather than held as a static snapshot) so
    // uploads/notes added below show up immediately as Firestore pushes the update.
    private var project: Project? {
        projectStore.projects.first { $0.id == projectId }
    }

    var body: some View {
        Group {
            if let project {
                List {
                    Section("Overview") {
                        LabeledContent("Status") {
                            StatusBadge(status: project.status)
                        }
                        LabeledContent("Address", value: project.address)
                        Text(project.projectDescription)
                            .foregroundStyle(.secondary)
                    }

                    Section("Roadmap & Checklist") {
                        ProgressView(value: project.progress) {
                            Text("\(project.tasksCompleted) of \(project.totalTasks) tasks complete")
                                .font(.caption)
                        }
                        ForEach(0..<3) { index in
                            Label("Sample task \(index + 1)", systemImage: index < project.tasksCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(index < project.tasksCompleted ? .primary : .secondary)
                        }
                    }

                    Section("AI Chat") {
                        NavigationLink {
                            Text("AI project chat coming soon.")
                                .foregroundStyle(.secondary)
                                .navigationTitle("AI Assistant")
                        } label: {
                            Label("Ask about this project", systemImage: "sparkles")
                        }
                    }

                    Section("Contractors") {
                        Label("No contractors invited yet", systemImage: "person.2")
                            .foregroundStyle(.secondary)
                    }

                    Section("Uploaded Documents") {
                        if project.documents.isEmpty {
                            Text("No documents uploaded yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(project.documents) { document in
                                documentRow(document, project: project)
                            }
                        }

                        Button {
                            isShowingDocumentPicker = true
                        } label: {
                            if isUploadingDocument {
                                HStack {
                                    ProgressView()
                                    Text("Uploading...")
                                }
                            } else {
                                Label("Add Document", systemImage: "paperclip")
                            }
                        }
                        .disabled(isUploadingDocument)
                    }

                    Section("Misc Notes") {
                        if project.notes.isEmpty {
                            Text("No notes yet")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(project.notes.sorted { $0.createdAt > $1.createdAt }) { note in
                                noteRow(note, project: project)
                            }
                        }

                        HStack {
                            TextField("Add a note", text: $newNoteText, axis: .vertical)
                            Button {
                                addNote(to: project)
                            } label: {
                                if isAddingNote {
                                    ProgressView()
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                }
                            }
                            .disabled(isAddingNote || newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .navigationTitle(project.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView(
                    "Project Not Found",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This project may have been deleted.")
                )
            }
        }
        .fileImporter(isPresented: $isShowingDocumentPicker, allowedContentTypes: [.item]) { result in
            handlePickedFile(result)
        }
        .alert("Error", isPresented: errorIsPresented) {
            Button("Ok", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func documentRow(_ document: ProjectDocument, project: Project) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(document.fileName)
                    .font(.subheadline)
                Text(document.uploadedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let url = URL(string: document.downloadURL) {
                Link(destination: url) {
                    Image(systemName: "arrow.down.circle")
                }
            }
        }
        .swipeActions {
            Button(role: .destructive) {
                deleteDocument(document, from: project)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func noteRow(_ note: ProjectNote, project: Project) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(note.text)
            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .swipeActions {
            Button(role: .destructive) {
                deleteNote(note, from: project)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func handlePickedFile(_ result: Result<URL, Error>) {
        guard let project else { return }
        isUploadingDocument = true
        Task {
            defer { isUploadingDocument = false }
            do {
                let url = try result.get()
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url)
                let pending = PendingProjectDocument(fileName: url.lastPathComponent, data: data)
                try await projectStore.addDocument(pending, to: project)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func addNote(to project: Project) {
        isAddingNote = true
        let text = newNoteText
        Task {
            defer { isAddingNote = false }
            do {
                try await projectStore.addNote(text: text, to: project)
                newNoteText = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteDocument(_ document: ProjectDocument, from project: Project) {
        Task {
            do {
                try await projectStore.deleteDocument(document, from: project)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteNote(_ note: ProjectNote, from project: Project) {
        Task {
            do {
                try await projectStore.deleteNote(note, from: project)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}


private struct NewProjectView: View {
    @EnvironmentObject private var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var address = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var pendingDocuments: [StagedDocument] = []
    @State private var isShowingDocumentPicker = false

    @State private var noteDrafts: [String] = []
    @State private var newNoteText = ""

    private struct StagedDocument: Identifiable {
        let id = UUID()
        let fileName: String
        let data: Data
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Project name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Property") {
                    TextField("Address", text: $address)
                }

                Section("Documents") {
                    if pendingDocuments.isEmpty {
                        Text("No documents attached yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pendingDocuments) { document in
                            Text(document.fileName)
                        }
                        .onDelete { pendingDocuments.remove(atOffsets: $0) }
                    }

                    Button {
                        isShowingDocumentPicker = true
                    } label: {
                        Label("Attach Document", systemImage: "paperclip")
                    }
                }

                Section("Misc Notes") {
                    if !noteDrafts.isEmpty {
                        ForEach(Array(noteDrafts.enumerated()), id: \.offset) { _, note in
                            Text(note)
                        }
                        .onDelete { noteDrafts.remove(atOffsets: $0) }
                    }

                    HStack {
                        TextField("Add a note", text: $newNoteText, axis: .vertical)
                        Button {
                            let cleaned = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !cleaned.isEmpty else { return }
                            noteDrafts.append(cleaned)
                            newNoteText = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Create") { createProject() }
                            .disabled(name.isEmpty || address.isEmpty || description.isEmpty)
                    }
                }
            }
            .fileImporter(isPresented: $isShowingDocumentPicker, allowedContentTypes: [.item]) { result in
                handlePickedFile(result)
            }
            .alert("Couldn't Create Project", isPresented: errorIsPresented) {
                Button("Ok", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func handlePickedFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            pendingDocuments.append(StagedDocument(fileName: url.lastPathComponent, data: data))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func createProject() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await projectStore.createProject(
                    name: name,
                    projectDescription: description,
                    address: address,
                    noteTexts: noteDrafts,
                    pendingDocuments: pendingDocuments.map { PendingProjectDocument(fileName: $0.fileName, data: $0.data) }
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    ProjectsView()
        .environmentObject(ProjectStore())
}
