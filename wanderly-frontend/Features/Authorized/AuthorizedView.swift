//
//  AuthorizedView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//

import SwiftUI

struct AuthorizedView: View {
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
            await viewModel.loadUser()
        }
    }
}

#Preview {
    AuthorizedView()
}
