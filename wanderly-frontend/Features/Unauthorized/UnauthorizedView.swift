//
//  UnauthorizedView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//

import SwiftUI

struct UnauthorizedView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = UnauthorizedViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.unauthFlow {
                case .login:
                    LoginView(viewModel: viewModel)
                        .transition(.blurReplace)
                case .register:
                    RegisterView(viewModel: viewModel)
                        .transition(.blurReplace)
                case .verification:
                    VerificationView(viewModel.email, viewModel.password)
                        .transition(.move(edge: .trailing))
                }
            }
            .toolbar {
                if viewModel.unauthFlow == .verification {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("", systemImage: "chevron.left") {
                            withAnimation {
                                viewModel.unauthFlow = .register
                            }
                        }
                    }
                }
            }
            .onAppear {
                viewModel.unauthFlow = .login
                
                viewModel.email = "sergienkoyura5@gmail.com"
                viewModel.password = "dfgfdgdfgdfg1"
            }
            .hideKeyboardOnTapOutside()
        }
    }
}

#Preview {
    UnauthorizedView()
        .environmentObject(AppState.shared)
}
