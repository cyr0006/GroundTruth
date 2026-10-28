//
//  RootView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 23/9/2026.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

struct RootView: View {
    var body: some View {
        if FirebaseApp.app() == nil {
            FirebaseSetupView()
        } else {
            AuthenticatedRootView()
        }
        
    }
}

private struct AuthenticatedRootView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var projectStore = ProjectStore()
    
    var body: some View {
        Group{
            if authService.isCheckingAuthentication{
                ProgressView("Checking your account...")
            } else if authService.user == nil {
                AuthenticationView()
            } else {
                MainTabView()
            }
        }
        .environmentObject(authService)
        .environmentObject(projectStore)
        .onChange(of: authService.user?.uid, initial: true){_, userID in
            if let userID {
                projectStore.startListening(for: userID)
            } else {
                projectStore.stopListening()
            }
        }
    }
    
}

private struct FirebaseSetupView: View {
    var body: some View {
        ContentUnavailableView{
            Label("Firebase Setup Required", systemImage: "flame.fill")
        } description: {
            Text("Add GoogleService-Info-3.plist to the GroundTruth target, then run the app again.")
        } actions: {
            Text("Please visit Firebase Concol to set up ")
        }
    }
}
