//
//  QuizViewModel.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 02.05.2025.
//
import Foundation

@MainActor
final class QuizViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var city: CityDto = CityDto()
    @Published var travelType: TravelType = .FOOT
    @Published var routeTime: Double = 2
    @Published var activityType: ActivityType = .COMBINED
    @Published var isRequestingLocation = false
    
    @Published var errorMessage: String?
    
    func savePreferences(onSuccess: () -> Void) async {
        isRequestingLocation = true
        errorMessage = nil
        
        defer { isRequestingLocation = false }
        
        guard validateInputs() else {
            return
        }
        
        do {
            onSuccess()
            
            let userProfile = UserProfileDto(name: name, avatarName: "AVATAR_1")
            let userPreferences = UserPreferencesDto(travelType: travelType, timePerRoute: Int(routeTime), activityType: activityType, city: city)
            
            AppState.shared.currentUserProfile = try await UserService.saveUserProfile(profile: userProfile)
            AppState.shared.currentUserPreferences = try await GeoService.saveUserPreferences(prefs: userPreferences)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func validateInputs() -> Bool {
        if name.isEmpty || city.name.isEmpty {
            errorMessage = "Name and city are required"
            return false;
        }
        
        clearErrors()
        return true
    }
    
    func clearErrors() {
        errorMessage = nil
    }
    
}
