//
//  MainTabView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//


import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            MapView()
                .tabItem { Label("Map", systemImage: "map") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}


#Preview {
    MainTabView()
        .environmentObject(AppState.shared)
        .environmentObject(OverviewState.shared)
}
