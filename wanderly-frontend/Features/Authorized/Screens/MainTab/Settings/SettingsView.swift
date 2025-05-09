//
//  SettingsView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 03.05.2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel = SettingsViewModel()
    @EnvironmentObject private var appState: AppState
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            if let user = viewModel.userDto, let profile = viewModel.userProfileDto, let prefs = viewModel.userPreferencesDto {
                content(user: user, profile: profile, prefs: prefs)
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
    }
    
    @ViewBuilder
    private func content(user: UserDto, profile: UserProfileDto, prefs: UserPreferencesDto) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Hi, \(profile.name)")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(.primary))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.email)
                            .font(.body)
                            .foregroundStyle(Color(.primary))
                            .bold()
                        
                        Text("Created at \(formatted(dateString: user.createdAt))")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.primary)))
                    
                    AutocompleteCitySheet(city: Binding(
                        get: { prefs.city },
                        set: { viewModel.userPreferencesDto?.city = $0 }
                    ))
                    
                    Picker("Travel type", selection: Binding(
                        get: { prefs.travelType },
                        set: { viewModel.userPreferencesDto?.travelType = $0 }
                    )) {
                        ForEach(TravelType.allCases, id: \.self) {
                            Text($0.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.primary)))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time per route: \(prefs.timePerRoute)h")
                        Slider(
                            value: Binding(
                                get: { Double(prefs.timePerRoute) },
                                set: { viewModel.userPreferencesDto?.timePerRoute = Int($0) }
                            ),
                            in: 1...10,
                            step: 1
                        )
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.primary)))
                    
                    Picker("Activity type", selection: Binding(
                        get: { prefs.activityType },
                        set: { viewModel.userPreferencesDto?.activityType = $0 }
                    )) {
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
                
                VStack(spacing: 12) {
                    Button("Save Changes") {
                        Task {
                            await viewModel.savePreferences()
                        }
                    }
                    .disabled(viewModel.isSaving)
                    .buttonStyle(ProminentButtonStyle())
                    
                    Button("Logout") {
                        appState.logout()
                    }
                    .buttonStyle(ProminentButtonStyle())
                    
                    Button("Delete Account") {
                        viewModel.deleteAccount()
                    }
                    .foregroundColor(.red)
                    .font(.footnote)
                }
                
                Spacer()
            }
            .hideKeyboardOnTapOutside()
            .padding(.horizontal, 24)
            .background(Color.white.ignoresSafeArea())
            .navigationBarBackButtonHidden()
        }
    }
    
    private func formatted(dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        
        if let date = inputFormatter.date(from: dateString) {
            return displayFormatter.string(from: date)
        } else {
            return "Unknown"
        }
    }
    
    
}

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
}
