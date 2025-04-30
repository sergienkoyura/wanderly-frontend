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
    @State var authFlow: AuthorizedFlow = .quiz
    
    var body: some View {
        switch authFlow {
        case .quiz:
            QuizView()
        case .main:
            MainTabView()
        }
    }
}

#Preview {
    AuthorizedView()
}
