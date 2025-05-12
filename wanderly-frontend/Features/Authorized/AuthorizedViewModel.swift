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
    
    func loadUser() async {
        do {
            withAnimation {
                authFlow = .main
            }
            AppState.shared.currentUser = try await AuthService.getUser()
            AppState.shared.currentUserProfile = try await UserService.getUserProfile()
            AppState.shared.currentUserPreferences = try await GeoService.getUserPreferences()
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
