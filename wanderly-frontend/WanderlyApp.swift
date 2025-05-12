//
//  WanderlyApp.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//

import SwiftUI

@main
struct WanderlyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var appState = AppState.shared
    @StateObject var overviewState = OverviewState.shared
//    @StateObject var watchSessionManager = WatchSessionManager.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(overviewState)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background || newPhase == .inactive {
                        // App going to background or inactive
                        WatchSessionManager.shared.sendRouteStatus(routeIndex: 0, isPlaying: false)
                    }
                }
//                .environmentObject(watchSessionManager)
        }
    }
}
