//
//  SettingsViewModel.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 03.05.2025.
//
import Foundation
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isSaving = false
    
    @Published var errorMessage: String?

    @Published var userDto: UserDto?
    @Published var userProfileDto: UserProfileDto?
    @Published var userPreferencesDto: UserPreferencesDto?
    
    private var firstLoad = false;
    
    func load() async {
        print("loading settings...")
        userDto = AppState.shared.currentUser
        userProfileDto = AppState.shared.currentUserProfile
        userPreferencesDto = AppState.shared.currentUserPreferences
    }
    
    func logout() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await AuthService.logout()
        } catch {
            self.errorMessage = "Failed to logout"
            print("logout error: \(error)")
        }
    }

    func savePreferences() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            
            AppState.shared.currentUserPreferences = try await GeoService.saveUserPreferences(prefs: userPreferencesDto!)
            OverviewState.shared.showToast()
        } catch {
            self.errorMessage = "Failed to save preferences"
            print("Save error: \(error)")
        }
    }

    func deleteAccount() {
        // TODO: Add confirmation & actual deletion logic
        print("Account deletion requested")
    }
}
