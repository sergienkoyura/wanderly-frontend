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
    
    static func generateRoute(cityId: UUID) async throws -> RouteDto {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "routes/generate/\(cityId)",
            method: "GET"
        )!
    }
    
    static func deleteRouteById(routeId: UUID) async throws {
        let _: EmptyResponse? = try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "routes/\(routeId)",
            method: "DELETE"
        )
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
    
    static func saveRoute(route: RouteDto) async throws -> RouteDto {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "routes",
            method: "POST",
            body: route
        )!
    }
    
    static func branchRoute(routeId: UUID, markerIndex: Int) async throws -> RouteDto {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "routes/branch",
            method: "POST",
            body: BranchRequest(routeId: routeId, markerIndex: markerIndex)
        )!
    }
    
    static func getModels(cityId: UUID) async throws -> [ARModelDto] {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "ar-models/\(cityId)",
            method: "GET"
        )!
    }
    
    static func verifyModel(modelCompletionRequest: ModelCompletionRequest) async throws  {
        let _: EmptyResponse? = try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "ar-models/verify",
            method: "POST",
            body: modelCompletionRequest
        )
    }
}
    
