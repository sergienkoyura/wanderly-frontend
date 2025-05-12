//
//  RouteStatusView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 11.05.2025.
//
import SwiftUI
import WatchConnectivity

struct WatchRouteView: View {
    @ObservedObject var manager = WatchConnectivityManager.shared
    
    var body: some View {
        VStack(spacing: 10) {
            if manager.isPlayingRoute {
                Text("Route \(manager.routeIndex)")
                Text("Step \(manager.currentStep + 1)/\(manager.totalSteps)")
                    .font(.headline)
                ProgressView(value: Double(manager.currentStep + 1), total: Double(manager.totalSteps))
                Button("Next") {
                    manager.sendNextStep()
                }
            } else {
                Text("Start a route from iPhone")
                    .font(.footnote)
            }
        }
        .padding()
    }
}

#Preview {
    WatchRouteView()
}
