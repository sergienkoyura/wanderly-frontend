//
//  QuizView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//

import SwiftUI
import CoreLocation

struct QuizView: View {
    let onFinish: () -> Void
    @StateObject private var viewModel = QuizViewModel()
    @EnvironmentObject private var appState: AppState
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Introduce Yourself")
                .font(.title)
                .bold()
                .foregroundColor(Color(.primary))
            
            VStack(spacing: 16) {
                TextField("Your name", text: $viewModel.name)
                    .focused($focusedField, equals: .name)
                    .textFieldStyle(OutlinedTextFieldStyle(isActive: focusedField == .name, isPassword: false))
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .onTapGesture {
                        focusedField = .name
                    }
                
                AutocompleteCitySheet(city: $viewModel.city)
                
                Picker("Travel type", selection: $viewModel.travelType) {
                    ForEach(TravelType.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.primary)))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time per route: \(Int(viewModel.routeTime))h")
                    Slider(value: $viewModel.routeTime, in: 1...10, step: 1)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.primary)))
                
                Picker("Activity type", selection: $viewModel.activityType) {
                    ForEach(ActivityType.allCases, id: \.self) {
                        Text($0.rawValue.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.primary)))
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(Color(.error))
                    .font(.footnote)
            }
            
            Button(action: {
                Task {
                    await viewModel.savePreferences(onSuccess: onFinish)
                }
            }) {
                if viewModel.isRequestingLocation {
                    ProgressView()
                } else {
                    Text("Continue")
                }
            }
            .buttonStyle(ProminentButtonStyle())
            .disabled(viewModel.isRequestingLocation)
            
//            Button("Logout") {
//                appState.logout()
//            }
//            .buttonStyle(ProminentButtonStyle())
            
            Spacer()
        }
        .hideKeyboardOnTapOutside()
        .padding(.horizontal, 24)
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    QuizView(onFinish: {})
        .environmentObject(AppState.shared)
}
