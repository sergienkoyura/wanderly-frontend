//
//  RootView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//


import SwiftUI


struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var overviewState: OverviewState
    
    
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
        .overlay(
            Group {
                if let message = OverviewState.shared.toastMessage {
                    Text(message)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.thinMaterial)
                        .foregroundStyle(Color(.primary))
                        .cornerRadius(8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                }
            },
            alignment: .top
        )
    }
}

#Preview {
    RootView()
        .environmentObject(AppState.shared)
        .environmentObject(OverviewState.shared)
}
