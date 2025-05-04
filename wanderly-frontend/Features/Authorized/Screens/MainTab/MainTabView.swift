//
//  MainTabView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//


import SwiftUI

struct MainTabView: View {
//    @StateObject private var settingsViewModel: SettingsViewModel
//    @StateObject private var mapViewModel: MapViewModel
//    
//    init() {
//        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(userDto: UserState.shared.user!, userPreferencesDto: UserState.shared.preferences!) {
//            withAnimation {
//                OverviewState.shared.showToast()
//                print("show toast")
//            }
//        })
//        
//        _mapViewModel = StateObject(wrappedValue: MapViewModel(userPreferencesDto: UserState.shared.preferences!))
//    }
    
    var body: some View {
        TabView {
            MapView()
                .tabItem { Label("Map", systemImage: "map") }

            StatisticsView()
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
