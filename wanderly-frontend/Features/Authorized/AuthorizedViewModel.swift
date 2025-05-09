//
//  AuthorizedViewModel.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 04.05.2025.
//
import SwiftUI

enum AuthorizedFlow {
    case quiz
    case main
}

@MainActor
final class AuthorizedViewModel: ObservableObject {
    @Published var authFlow: AuthorizedFlow?
    
    func loadUser(onSuccess: @escaping (UserDto, UserProfileDto, UserPreferencesDto) -> Void) async {
        do {
            let user = try await AuthService.getUser()
            let userProfile = try await UserService.getUserProfile()
            let userPreferences = try await GeoService.getUserPreferences()
            withAnimation {
                authFlow = .main
            }
            onSuccess(user, userProfile, userPreferences)
        } catch {
            print("Error loading user: \(error)")
            withAnimation {
                authFlow = .quiz
            }
        }
    }

    func completeQuiz() {
        withAnimation {
            authFlow = .main
        }
        OverviewState.shared.showToast()
    }
    
}
