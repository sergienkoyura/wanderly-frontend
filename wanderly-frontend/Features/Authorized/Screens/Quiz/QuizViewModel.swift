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
            let prefs = UserPreferencesDto(name: name, travelType: travelType, timePerRoute: Int(routeTime), activityType: activityType, city: city)
            try await UserService.savePreferences(prefs: prefs)
            onSuccess()
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
