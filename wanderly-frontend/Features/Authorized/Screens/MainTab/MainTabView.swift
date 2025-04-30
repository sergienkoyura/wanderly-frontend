//
//  MainTabView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//


import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView {
            Text("Map")      // Here later will be your MapView
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            Text("Stats")    // Here will be your AchievementsView
                .tabItem {
                    Label("Statistics", systemImage: "chart.bar")
                }
            
            
            VStack {
                Text("Settings")
                Button("Logout") {
                    appState.logout()
                }.buttonStyle(ProminentButtonStyle())
            }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
