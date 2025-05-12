//
//  wanderlyApp.swift
//  wanderly Watch App
//
//  Created by Yurii Serhiienko on 11.05.2025.
//

import SwiftUI

@main
struct wanderly_Watch_AppApp: App {
    @StateObject var connectivity = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchRouteView()
                .environmentObject(connectivity)
        }
    }
}
