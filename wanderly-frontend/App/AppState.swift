//
//  AppState.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//


import SwiftUI

enum AppFlow {
    case authorized
    case unauthorized
}

@MainActor
final class AppState: ObservableObject {
    @Published var appFlow: AppFlow?
    @Published var isAuthenticated: Bool
    
    @Published var currentUser: UserDto? = nil
    @Published var currentUserProfile: UserProfileDto? = nil
    @Published var currentUserPreferences: UserPreferencesDto? = nil
    
    static let shared: AppState = AppState()
    private init() {
        self.appFlow = TokenStorage.getAccessToken() != nil ? .authorized : .unauthorized
        
        self.isAuthenticated = TokenStorage.getAccessToken() != nil
    }
    
    func login(accessToken: String, refreshToken: String) {
        TokenStorage.saveAccessToken(accessToken)
        TokenStorage.saveRefreshToken(refreshToken)
        withAnimation {
            appFlow = .authorized
            isAuthenticated = true
        }
    }
    
    func logout() {
        TokenStorage.clearTokens()
        withAnimation {
            appFlow = .unauthorized
            isAuthenticated = false
        }
        
        currentUser = nil
        currentUserProfile = nil
        currentUserPreferences = nil
    }
}
