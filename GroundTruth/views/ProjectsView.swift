//
//  ProjectsView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI

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
                ProjectDetailView(project: project)
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
    let project: Project

    var body: some View {
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
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
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

    private func createProject() {
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                try await projectStore.createProject(
                    name: name,
                    projectDescription: description,
                    address: address
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
