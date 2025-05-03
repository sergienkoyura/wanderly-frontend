//
//  AuthorizedView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//

import SwiftUI

enum AuthorizedFlow {
    case quiz
    case main
}

struct AuthorizedView: View {
    @State var authFlow: AuthorizedFlow?
    
    var body: some View {
        ZStack {
            switch authFlow {
            case .quiz:
                QuizView(onFinish: { withAnimation { authFlow = .main } })
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
            do {
                let preferencesExist = try await UserService.checkPreferencesExist()
                print("Preferences exists: \(preferencesExist)")
                withAnimation { authFlow = preferencesExist ? .main : .quiz }
            } catch {
                print("Failed to load user preferences: \(error)")
                withAnimation { authFlow = .quiz }
            }
        }
    }
}

#Preview {
    AuthorizedView()
}
