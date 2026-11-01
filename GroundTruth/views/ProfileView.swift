//
//  ProfileView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject private var projectStore: ProjectStore
    @EnvironmentObject private var authService: AuthService
    @AppStorage(NotificationService.enabledKey) private var notificationsEnabled = true
    @State private var signoutConfirmationShowing = false
    @State private var showNotificationDeniedAlert = false
    
    private var displayName: String {
        authService.user?.displayName ?? "User"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(displayName)")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("\(authService.user?.email ?? "Email Not Available")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                }

                Section("Account") {
                    LabeledContent("Saved Projects", value: "\(projectStore.projects.count)")
                    NavigationLink("Personal Details") {
                        PersonalDetailsView()
                    }
                }

                Section("Preferences") {
                    Toggle(isOn: $notificationsEnabled) {
                        Label("Notifications", systemImage: "bell")
                    }
                    .onChange(of: notificationsEnabled) { _, isEnabled in
                        if isEnabled {
                            Task { _ = await NotificationService.requestAuthorizationIfNeeded() }
                        } else {
                            NotificationService.cancelAllReminders()
                        }
                    }

                    Button("Send Test Notification") {
                        Task {
                            let authorized = await NotificationService.requestAuthorizationIfNeeded()
                            if authorized {
                                NotificationService.sendTestNotification()
                            } else {
                                showNotificationDeniedAlert = true
                            }
                        }
                    }
                    .disabled(!notificationsEnabled)

                    NavigationLink {
                        Text("Appearance settings coming soon.")
                            .foregroundStyle(.secondary)
                            .navigationTitle("Appearance")
                    } label: {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                }

                Section("Support") {
                    NavigationLink {
                        FAQView()
                    } label: {
                        Label("FAQ & Help", systemImage: "questionmark.circle")
                    }
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About GroundTruth", systemImage: "info.circle")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        signoutConfirmationShowing = true
                    } label: {
                        Text("Sign Out")
                    }
                    .alert(isPresented: $signoutConfirmationShowing) {
                        Alert(
                            title: Text("Sign Out"),
                            message: Text("Are you sure you want to sign out?"),
                            primaryButton: .cancel(),
                            secondaryButton: .destructive(Text("Sign Out")) {
                                signOut()
                            }
                        )
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Notifications Disabled", isPresented: $showNotificationDeniedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable notifications for GroundTruth in iOS Settings to send a test reminder.")
            }
        }
    }
    
    private func signOut() {
         do {
             try authService.signOut()
         } catch {
             print("Failed to sign out: \(error)")
         }
     }
}

#Preview {
    ProfileView()
        .environmentObject(ProjectStore())
}
