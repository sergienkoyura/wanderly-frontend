//
//  LoginViewModel.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//

import SwiftUI

enum UnauthorizedFlow {
    case login
    case register
    case verification
}

@MainActor
final class UnauthorizedViewModel: ObservableObject {
    @Published var unauthFlow: UnauthorizedFlow = .login
    
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let appState: AppState
    
    init(appState: AppState = .shared) {
        self.appState = appState
    }
    
    func login() async {
        isLoading = true
        errorMessage = nil
        
        guard validateInputs() else {
            return
        }
        
        do {
            let response = try await AuthService.login(email: email, password: password)
            appState.login(accessToken: response.accessToken, refreshToken: response.refreshToken)
            print("logged in")
        } catch {
            print(error)
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func register() async {
        isLoading = true
        errorMessage = nil
        
        guard validateInputs() else {
            return
        }
        
        do {
            try await AuthService.register(email: email, password: password)
            
            switchTo(flow: .verification)
            print("sent the code")
        } catch {
            print(error)
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func switchTo(flow: UnauthorizedFlow) {
        withAnimation {
            unauthFlow = flow
            clearErrors()
        }
    }
    
    private func validateInputs() -> Bool {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Email cannot be blank"
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "Invalid email address"
            return false
        }
        
        if password.count < 8 {
            errorMessage = "Password must be at least 8 characters"
            return false
        }
        
        if password.count > 64 {
            errorMessage = "Password cannot be longer than 64 characters"
            return false
        }
        
        if !containsNumber(password) {
            errorMessage = "Password must contain at least one number"
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: email)
    }
    
    private func containsNumber(_ text: String) -> Bool {
        let numberRegex = ".*[0-9]+.*"
        return NSPredicate(format: "SELF MATCHES %@", numberRegex).evaluate(with: text)
    }
    
    func clearErrors() {
        errorMessage = nil
    }
}
