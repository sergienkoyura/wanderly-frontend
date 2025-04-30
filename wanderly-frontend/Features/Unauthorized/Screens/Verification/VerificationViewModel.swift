//
//  VerificationViewModel.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//


import Foundation

final class VerificationViewModel: ObservableObject {
    let email: String
    let password: String
    private let appState: AppState
    
    @Published var code: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init(_ email: String, _ password: String, _ appState: AppState = .shared) {
        self.email = email
        self.password = password
        self.appState = appState
    }
    
    
    func verify() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await AuthService.verify(email: email, password: password, code: code)
            appState.login(accessToken: response.accessToken, refreshToken: response.refreshToken)
        } catch {
            errorMessage = error.localizedDescription
            print(error)
        }
        
        isLoading = false
    }
    
    func resendCode() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AuthService.register(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
}
