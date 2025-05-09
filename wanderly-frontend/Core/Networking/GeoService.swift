//
//  GeoService.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 05.05.2025.
//


import Foundation

enum GeoService {
    private static var baseURL: URL { ApiClient.baseURL.appendingPathComponent("geo") }
    
    static func getMarkers(cityId: UUID) async throws -> [MarkerDto] {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "markers/\(cityId)",
            method: "GET"
        )!
    }
    
    static func getRoutes(cityId: UUID) async throws -> [RouteDto] {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "routes/\(cityId)",
            method: "GET"
        )!
    }
    
    static func getUserPreferences() async throws -> UserPreferencesDto {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "me",
            method: "GET"
        )!
    }
    
    static func saveUserPreferences(prefs: UserPreferencesDto) async throws -> UserPreferencesDto {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "me",
            method: "POST",
            body: prefs
        )!
    }
}
    
