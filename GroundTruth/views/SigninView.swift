//
//  SigninView.swift
//  GroundTruth
//
//  Created by Aryan Cyrus  on 15/9/2026.
//

import SwiftUI

struct AuthenticationView: View {
    private enum Mode: String, CaseIterable, Identifiable{
        case signIn = "Sign In"
        case createAccount = "Create Account"
        var id: String {rawValue}
    }
    
    @EnvironmentObject private var authService: AuthService
    @State private var mode = Mode.signIn
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(spacing: 24){
                    Image(systemName: "map.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.tint)
                    
                    VStack(spacing: 24){
                        Text("GroundTruth")
                            .font(.largeTitle.bold())
                        Text("You bring the what, we bring the how.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Picker("Authentication Mode", selection: $mode){
                        ForEach(Mode.allCases){Text($0.rawValue).tag($0)}
                    }
                    .pickerStyle(.segmented)
                    VStack(spacing: 14){
                        if mode == .createAccount {
                            TextField("Display name", text: $displayName)
                                .textContentType(.name)
                        }
                        
                        TextField("Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        SecureField("Password", text: $password)
                            .textContentType(mode == .signIn ? .password : .newPassword)
                    }
                    .textFieldStyle(.roundedBorder)
                    
                    Button(action: authenticate){
                        HStack{
                            if isWorking{ProgressView().tint(.white)}
                            Text(mode.rawValue).frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isWorking || email.isEmpty || password.isEmpty || (mode == .createAccount && displayName.isEmpty))
                }
                .padding(28)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .alert("Authentication Error", isPresented: errorIsPresented){
                Button("Ok", role: .cancel){errorMessage = nil}
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }
    
    private var errorIsPresented: Binding<Bool> {
        Binding(get: {errorMessage != nil}, set: {if !$0 {errorMessage = nil } })
    }
    
    private func authenticate(){
        isWorking = true
        
        Task{
            defer {isWorking = false}
            do {
                if mode == .signIn{
                    try await authService.signIn(email: email, password: password)
                } else {
                    try await authService.createAccount(displayName: displayName, email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

