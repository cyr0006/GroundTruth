//
//  CostEstimateInputSheet.swift
//  GroundTruth
//

import SwiftUI

enum ProjectType: String, CaseIterable, Identifiable {
    case newBuild = "New Build"
    case extensionWork = "Extension"
    case renovation = "Renovation"
    case outdoorWorks = "Outdoor Works"

    var id: String { rawValue }
}

struct CostEstimateInputSheet: View {
    let project: Project

    @EnvironmentObject private var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss

    @State private var floorAreaSqm: Double
    @State private var projectType: ProjectType
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(project: Project) {
        self.project = project
        let existing = project.costEstimateInputs
        _floorAreaSqm = State(initialValue: existing?.floorAreaSqm ?? 0)
        _projectType = State(initialValue: ProjectType(rawValue: existing?.projectType ?? "") ?? .newBuild)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Scope") {
                    TextField("Floor area (sqm)", value: $floorAreaSqm, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("Project type", selection: $projectType) {
                        ForEach(ProjectType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
            }
            .navigationTitle("Project Scope")
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
                            .disabled(floorAreaSqm <= 0)
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
                let inputs = CostEstimateInputs(floorAreaSqm: floorAreaSqm, projectType: projectType.rawValue)
                try await projectStore.setCostEstimateInputs(inputs, for: project)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
