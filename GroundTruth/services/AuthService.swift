//
//  AuthService.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore
internal import Combine

@MainActor
final class AuthService: ObservableObject{
    private static let displayNameLimit = 60
    
    @Published private(set) var user:  FirebaseAuth.User?
    @Published private(set) var isCheckingAuthentication = true
    
    private let auth: Auth
    private let database: Firestore
    private var authListener: AuthStateDidChangeListenerHandle?
    
    init (auth: Auth = .auth(), database: Firestore = .firestore()){
        self.auth = auth
        self.database = database
        authListener = auth.addStateDidChangeListener {[weak self] _, user in
            Task {@MainActor in
                self?.user = user
                self?.isCheckingAuthentication = false
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedEmail.isEmpty, !password.isEmpty else {
            throw AppError.invalidForm("Enter both an email address ana password.")
        }
        _ = try await auth.signIn(withEmail: cleanedEmail, password: password)
    }
    
    func createAccount(displayName: String , email: String, password: String) async throws {
        let cleanedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedName.isEmpty, !cleanedEmail.isEmpty else {
            throw AppError.invalidForm("Enter your name and email addres. ")
        }
        guard cleanedName.count <= Self.displayNameLimit else {
            throw AppError.invalidForm("Your name must be \(Self.displayNameLimit) characters or fewer")
        }
        guard password.count >= 6 else {
            throw AppError.invalidForm("The password must ocntain at least six characters.")
        }
        
        let result = try await auth.createUser(withEmail: cleanedEmail, password: password)
        let request = result.user.createProfileChangeRequest()
        request.displayName = cleanedName
        try await request.commitChanges()
        
        let profile = UserProfile(
            id: result.user.uid,
            displayName: cleanedName,
            email: cleanedEmail
        )
        do {
            try await database.collection("users")
                .document(profile.id)
                .setData(profile.creationData)

        } catch  {
            try? await result.user.delete()
            throw error
        }
    }
    
    func signOut() throws {
        try auth.signOut()
    }

    func refreshUser() async {
        try? await auth.currentUser?.reload()
        user = auth.currentUser
    }

}

