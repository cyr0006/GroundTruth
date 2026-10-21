//
//  PersonalDetailsView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 29/9/2026.
//

import SwiftUI
import FirebaseAuth

struct PersonalDetailsView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var name = ""
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Personal Details") {

                if isEditing {
                    TextField("Name", text: $name)
                } else {
                    LabeledContent("Name", value: name)
                }
            }
        }
        .onAppear {
            name = authService.user?.displayName ?? ""
        }
        .toolbar {
            if isSaving {
                ProgressView()
            } else {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task { await save() }
                    } else {
                        isEditing = true
                    }
                }
            }
        }
        .alert("Couldn't Update Name", isPresented: errorIsPresented) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func save() async {
        guard let user = Auth.auth().currentUser else { return }
        isSaving = true
        defer { isSaving = false }

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        do {
            try await changeRequest.commitChanges()
            await authService.refreshUser()
            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

