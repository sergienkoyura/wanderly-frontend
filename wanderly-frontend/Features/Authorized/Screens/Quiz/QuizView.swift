//
//  QuizView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//

import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var appState: AppState
    @State private var name: String = ""
       @State private var city: String = ""
       @State private var travelType: TravelType = .FOOT
       @State private var routeTime: Double = 2
       @State private var activityType: ActivityType = .COMBINED
       
       var body: some View {
           NavigationStack {
               
               Form {
                   Section(header: Text("Who are you?")) {
                       TextField("Your name", text: $name)
                           .textContentType(.name)
                           .autocapitalization(.words)
                       
                       AutocompleteCityField(city: $city)
                   }
                   Section(header: Text("Preferences")) {
                       
                       Picker("Travel type", selection: $travelType) {
                           ForEach(TravelType.allCases, id: \.self) {
                               Text($0.rawValue.capitalized)
                           }
                       }
                       .pickerStyle(SegmentedPickerStyle())
                       
                       VStack(alignment: .leading, spacing: 8) {
                           Text("Time per route: \(Int(routeTime))h")
                           Slider(value: $routeTime, in: 1...10, step: 1)
                       }
                       
                       Picker("Activity type", selection: $activityType) {
                           ForEach(ActivityType.allCases, id: \.self) {
                               Text($0.rawValue.capitalized)
                           }
                       }
                       .pickerStyle(SegmentedPickerStyle())
                       
                       Button("logout delete after") {
                           appState.logout()
                       }
                   }
               }
               .navigationTitle("Introduce Yourself")
           }
       }
}

#Preview {
    QuizView()
        .environmentObject(AppState.shared)
}
