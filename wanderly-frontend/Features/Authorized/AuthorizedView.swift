//
//  AuthorizedView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//

import SwiftUI

struct AuthorizedView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthorizedViewModel()
    
    var body: some View {
        ZStack {
            switch viewModel.authFlow {
            case .quiz:
                QuizView(onFinish: {
                    viewModel.completeQuiz()
                })
                    .transition(.blurReplace)
            case .main:
                MainTabView()
                    .transition(.blurReplace)
            case .none:
                ProgressView()
            }
        }
        .hideKeyboardOnTapOutside()
        .task {
            await viewModel.loadUser() { user, userProfile, userPreferences in
                appState.currentUser = user
                appState.currentUserProfile = userProfile
                appState.currentUserPreferences = userPreferences
            }
        }
    }
}

#Preview {
    AuthorizedView()
        .environmentObject(AppState.shared)
}
