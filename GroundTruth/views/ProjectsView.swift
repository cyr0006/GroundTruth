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
    @State private var projectPendingDelete: Project?

    // No NavigationStack here: this view is reused both as a tab root (MainTabView,
    // which supplies its own NavigationStack) and as a pushed destination (HomeView's
    // "See all" link, which pushes it onto its own NavigationStack). Nesting a second
    // NavigationStack inside the latter breaks `navigationDestination` and was causing
    // the white-screen-then-pop-back bug when drilling into a project from "See all".
    var body: some View {
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
                        .swipeActions {
                            Button(role: .destructive) {
                                projectPendingDelete = project
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
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
        .confirmationDialog(
            "Delete this project?",
            isPresented: projectPendingDeleteIsPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Project", role: .destructive) {
                if let project = projectPendingDelete {
                    deleteProject(project)
                }
            }
        } message: {
            Text("This permanently deletes the project, its tasks, notes, and documents.")
        }
    }

    private var projectErrorIsPresented: Binding<Bool> {
        Binding(
            get: { projectStore.errorMessage != nil },
            set: { if !$0 { projectStore.clearError() } }
        )
    }

    private var projectPendingDeleteIsPresented: Binding<Bool> {
        Binding(
            get: { projectPendingDelete != nil },
            set: { if !$0 { projectPendingDelete = nil } }
        )
    }

    private func deleteProject(_ project: Project) {
        Task {
            do {
                try await projectStore.deleteProject(project)
            } catch {
                projectStore.setError(error.localizedDescription)
            }
            projectPendingDelete = nil
        }
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

struct ProjectDetailView: View {
    let projectId: String

    @EnvironmentObject private var projectStore: ProjectStore
    @State private var isShowingDocumentPicker = false
    @State private var isUploadingDocument = false
    @State private var newNoteText = ""
    @State private var isAddingNote = false
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var newTaskDueDate: Date?
    @State private var isShowingDueDatePicker = false
    @State private var isAddingTask = false
    @State private var isShowingEditProject = false
    @State private var isShowingCostEstimateSheet = false
    @State private var isEditingTaskOrder = false
    @State private var errorMessage: String?
    
    private let costEstimator = CostEstimatorService()

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

                    Section("Cost Estimate") {
                        switch costEstimator.estimate(for: project.costEstimateInputs) {
                        case .available(let low, let high):
                            LabeledContent("Estimate") {
                                VStack(alignment: .trailing) {
                                    Text("\(low, format: .currency(code: "AUD")) – \(high, format: .currency(code: "AUD"))")
                                    Text("Preliminary")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Button("Edit Project Scope") { isShowingCostEstimateSheet = true }
                        case .unavailable:
                            Text("The project currently does not have enough information to provide an estimate. Add more project details, scope, or supporting documents to generate a cost estimate.")
                                .foregroundStyle(.secondary)
                            Button("Add Project Scope") { isShowingCostEstimateSheet = true }
                        }
                    }

                    roadmapSection(for: project)
                    
                    Section("Cost Estimate"){
                        switch costEstimator.estimate(for: project.costEstimateInputs) {
                        case .available(let low, let high):
                            LabeledContent("Estimate"){
                                VStack(alignment: .trailing){
                                    Text("\(low, format: .currency(code: "AUD")) - \(high, format: .currency(code: "AUD"))")
                                    Text("Preliminary")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Button("Edit Project Scope") {isShowingCostEstimateSheet = true}
                        case .unavailable:
                            Text("The project currently does not have enough information to provide an estimate. Add more details, scope or supporting documents to generate a cost estomate")
                                .foregroundStyle(.secondary)
                            Button("Add Project Scope", isShowingCostEstimateSheet = true)
                        }
                    }
                    
                    Section("AI Chat") {
                        NavigationLink {
                            ProjectChatView(project: project, projectStore: projectStore)
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
                .environment(\.editMode, .constant(isEditingTaskOrder ? .active : .inactive))
                .navigationTitle(project.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingEditProject = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
                .sheet(isPresented: $isShowingEditProject) {
                    EditProjectView(project: project)
                }
                .sheet(isPresented: $isShowingEditProject){
                    CostEstimateInputSheet(project: project)
                }
                
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

    @ViewBuilder
    private func roadmapSection(for project: Project) -> some View {
        Section {
            ProgressView(value: project.progress) {
                Text("\(project.tasksCompleted) of \(project.totalTasks) tasks complete")
                    .font(.caption)
            }

            if project.tasks.isEmpty {
                Text("No steps yet")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(project.tasks) { task in
                    taskRow(task, project: project)
                }
                .onMove { source, destination in
                    moveTasks(in: project, fromOffsets: source, toOffset: destination)
                }
            }

            addStepRow(to: project)

            if isShowingDueDatePicker {
                dueDatePicker
            }
        } header: {
            roadmapSectionHeader(for: project)
        }
    }

    private func addStepRow(to project: Project) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField("Add a step", text: $newTaskTitle)

            Button {
                isShowingDueDatePicker.toggle()
            } label: {
                Image(systemName: newTaskDueDate == nil ? "calendar.badge.plus" : "calendar.badge.clock")
                    .foregroundStyle(newTaskDueDate == nil ? .secondary : Color.accentColor)
            }
            .buttonStyle(.plain)

                Button {
                    addTask(to: project)
                } label: {
                    if isAddingTask {
                        ProgressView()
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .disabled(isAddingTask || newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            TextField("Description (optional)", text: $newTaskDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var dueDatePicker: some View {
        DatePicker(
            "Due date",
            selection: Binding(
                get: { newTaskDueDate ?? Date() },
                set: { newTaskDueDate = $0 }
            ),
            displayedComponents: .date
        )

        if newTaskDueDate != nil {
            Button("Remove Due Date", role: .destructive) {
                newTaskDueDate = nil
            }
            .font(.caption)
        }
    }

    private func roadmapSectionHeader(for project: Project) -> some View {
        HStack {
            Text("Roadmap & Checklist")
            Spacer()
            if isEditingTaskOrder || project.tasks.count > 1 {
                Button {
                    isEditingTaskOrder.toggle()
                } label: {
                    Text(isEditingTaskOrder ? "Done" : "Reorder")
                }
                .font(.caption)
            }
        }
        .textCase(nil)
    }

    private func taskRow(_ task: ProjectTask, project: Project) -> some View {
        Button {
            toggleTask(task, project: project)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .foregroundStyle(.primary)
                        .strikethrough(task.isCompleted)

                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let dueDate = task.dueDate {
                        Text(dueDateLabel(dueDate, isCompleted: task.isCompleted))
                            .font(.caption2)
                            .foregroundStyle(dueDateColor(dueDate, isCompleted: task.isCompleted))
                    }
                }
            } icon: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? Color.accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
        .swipeActions {
            Button(role: .destructive) {
                deleteTask(task, project: project)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func dueDateLabel(_ date: Date, isCompleted: Bool) -> String {
        let formatted = date.formatted(date: .abbreviated, time: .omitted)
        if !isCompleted && date < Date() {
            return "Overdue — was due \(formatted)"
        }
        return "Due \(formatted)"
    }

    private func dueDateColor(_ date: Date, isCompleted: Bool) -> Color {
        guard !isCompleted else { return .secondary }
        if date < Date() { return .red }
        let soonThreshold = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? date
        return date < soonThreshold ? .orange : .secondary
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

    private func addTask(to project: Project) {
        isAddingTask = true
        let title = newTaskTitle
        let description = newTaskDescription
        let dueDate = newTaskDueDate
        Task {
            defer { isAddingTask = false }
            do {
                try await projectStore.addTask(title: title, description: description, dueDate: dueDate, to: project)
                newTaskTitle = ""
                newTaskDescription = ""
                newTaskDueDate = nil
                isShowingDueDatePicker = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func toggleTask(_ task: ProjectTask, project: Project) {
        Task {
            do {
                try await projectStore.setTaskCompleted(task, isCompleted: !task.isCompleted, in: project)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteTask(_ task: ProjectTask, project: Project) {
        Task {
            do {
                try await projectStore.deleteTask(task, from: project)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func moveTasks(in project: Project, fromOffsets source: IndexSet, toOffset destination: Int) {
        Task {
            do {
                try await projectStore.moveTasks(in: project, fromOffsets: source, toOffset: destination)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}


struct NewProjectView: View {
    @EnvironmentObject private var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var address = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var status: ProjectStatus = .planning

    @State private var pendingDocuments: [StagedDocument] = []
    @State private var isShowingDocumentPicker = false

    @State private var noteDrafts: [String] = []
    @State private var newNoteText = ""

    @State private var taskDrafts: [String] = []
    @State private var newTaskTitle = ""

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
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Property") {
                    AddressSearchField(text: $address, placeholder: "Address")
                }

                Section("Roadmap & Checklist") {
                    if !taskDrafts.isEmpty {
                        ForEach(Array(taskDrafts.enumerated()), id: \.offset) { _, task in
                            Text(task)
                        }
                        .onDelete { taskDrafts.remove(atOffsets: $0) }
                    }

                    HStack {
                        TextField("Add a step", text: $newTaskTitle)
                        Button {
                            let cleaned = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !cleaned.isEmpty else { return }
                            taskDrafts.append(cleaned)
                            newTaskTitle = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
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
                    status: status,
                    noteTexts: noteDrafts,
                    pendingDocuments: pendingDocuments.map { PendingProjectDocument(fileName: $0.fileName, data: $0.data) },
                    taskTitles: taskDrafts
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct EditProjectView: View {
    let project: Project

    @EnvironmentObject private var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var address: String
    @State private var status: ProjectStatus
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(project: Project) {
        self.project = project
        _name = State(initialValue: project.name)
        _description = State(initialValue: project.projectDescription)
        _address = State(initialValue: project.address)
        _status = State(initialValue: project.status)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Project name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }

                Section("Property") {
                    AddressSearchField(text: $address, placeholder: "Address")
                }
            }
            .navigationTitle("Edit Project")
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
                        Button("Save") { saveChanges() }
                            .disabled(name.isEmpty || address.isEmpty || description.isEmpty)
                    }
                }
            }
            .alert("Couldn't Save Changes", isPresented: errorIsPresented) {
                Button("Ok", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func saveChanges() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await projectStore.updateProject(
                    project,
                    name: name,
                    projectDescription: description,
                    address: address,
                    status: status
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProjectsView()
    }
    .environmentObject(ProjectStore())
}
