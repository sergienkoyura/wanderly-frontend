//
//  RootView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//


import SwiftUI



struct RootView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        ZStack {
            switch appState.appFlow {
            case .authorized:
                AuthorizedView()
                    .transition(.move(edge: .bottom))
            case .unauthorized:
                UnauthorizedView()
                    .transition(.move(edge: .top))
            case .none:
                ProgressView()
            }
        }
        .animation(.easeInOut, value: appState.appFlow)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState.shared)
}
