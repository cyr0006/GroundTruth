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
            Button(isEditing ? "Save" : "Edit") {

                if isEditing {
                    updateName(name: name)
                }

                isEditing.toggle()
            }
        }
    }
    
    
    private func updateName(name: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        
        changeRequest.commitChanges { error in
        if let error = error {
        print("Failed to update name: \(error.localizedDescription)")
        } else {
        print("Name updated successfully")
        }
        }
    }
}

