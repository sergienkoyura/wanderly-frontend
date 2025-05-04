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
    @Published var userPreferencesDto: UserPreferencesDto?
    
    private var firstLoad = false;
    
    func load() async {
        guard !firstLoad else { return }
        firstLoad = true;
        
        isLoading = true;
        defer { isLoading = false }
        
        print("loading user data...")
        
        do {
            userDto = try await AuthService.me()
            userPreferencesDto = try await UserService.me()
        } catch {
            self.errorMessage = "Failed to load user data"
            print("Load error: \(error)")
            
            userPreferencesDto = nil
        }
    }

    func savePreferences() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await UserService.savePreferences(prefs: userPreferencesDto!)
            AppState.shared.currentCity = userPreferencesDto?.city
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
