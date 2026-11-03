//
//  CostEstimateInputSheet.swift
//  GroundTruth
//

import SwiftUI

enum ProjectType: String, CaseIterable, Identifiable {
    case newBuild = "New Build"
    case extensionWork = "Extension"
    case renovation = "Renovation"
    case outdoorStructure = "Outdoor Structure"
    case boundaryCivilWorks = "Boundary & Civil Works"

    var id: String { rawValue }

    /// Boundary & Civil Works (fences/retaining walls/pools) has no meaningful floor area in the
    /// training data - it's keyed off `BoundaryWorkSubtype` instead. See `CostEstimatorService`.
    var requiresFloorArea: Bool { self != .boundaryCivilWorks }
}

enum BoundaryWorkSubtype: String, CaseIterable, Identifiable {
    case fence = "Fence"
    case retainingWall = "Retaining Wall"
    case pool = "Swimming Pool"
    case other = "Other"

    var id: String { rawValue }
}

struct CostEstimateInputSheet: View {
    let project: Project

    @EnvironmentObject private var projectStore: ProjectStore
    @Environment(\.dismiss) private var dismiss

    @State private var floorAreaSqm: Double
    @State private var projectType: ProjectType
    @State private var workSubtype: BoundaryWorkSubtype
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(project: Project) {
        self.project = project
        let existing = project.costEstimateInputs
        _floorAreaSqm = State(initialValue: existing?.floorAreaSqm ?? 0)
        _projectType = State(initialValue: ProjectType(rawValue: existing?.projectType ?? "") ?? .newBuild)
        _workSubtype = State(initialValue: BoundaryWorkSubtype(rawValue: existing?.workSubtype ?? "") ?? .fence)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Scope") {
                    Picker("Project type", selection: $projectType) {
                        ForEach(ProjectType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }

                    if projectType.requiresFloorArea {
                        TextField("Floor area (sqm)", value: $floorAreaSqm, format: .number)
                            .keyboardType(.decimalPad)
                    } else {
                        Picker("Type of work", selection: $workSubtype) {
                            ForEach(BoundaryWorkSubtype.allCases) { subtype in
                                Text(subtype.rawValue).tag(subtype)
                            }
                        }
                        Text("Fences rarely need a building permit in Victoria, so this is a rule-of-thumb range, not a model prediction.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                            .disabled(projectType.requiresFloorArea && floorAreaSqm <= 0)
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
                let inputs = CostEstimateInputs(
                    floorAreaSqm: projectType.requiresFloorArea ? floorAreaSqm : 0,
                    projectType: projectType.rawValue,
                    workSubtype: projectType.requiresFloorArea ? nil : workSubtype.rawValue
                )
                try await projectStore.setCostEstimateInputs(inputs, for: project)
                dismiss()

                // Fire-and-forget: re-assess against the just-saved scope in the background
                // rather than blocking dismissal on a network call. The cost screen shows
                // "Not yet assessed" / a loading state until this lands via the Firestore
                // listener, same pattern as everything else in ProjectStore.
                var scopedProject = project
                scopedProject.costEstimateInputs = inputs
                Task {
                    try? await projectStore.assessProjectCompliance(for: scopedProject)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
