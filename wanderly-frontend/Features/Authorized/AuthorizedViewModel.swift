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
            let hasPreferences = try await UserService.checkPreferencesExist()
            withAnimation {
                authFlow = hasPreferences ? .main : .quiz
            }
        } catch {
            print("Error loading user: \(error)")
        }
    }

    func completeQuiz() {
        withAnimation {
            authFlow = .main
        }
        OverviewState.shared.showToast()
    }
    
}
