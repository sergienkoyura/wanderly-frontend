//
//  UserService.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 01.05.2025.
//
import Foundation

enum UserService {
    private static var baseURL: URL { ApiClient.baseURL.appendingPathComponent("user") }

    static func saveUserProfile(profile: UserProfileDto) async throws {
        let _: EmptyResponse? = try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "me",
            method: "POST",
            body: profile
        )
    }
    
    static func getUserProfile() async throws -> UserProfileDto {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "me",
            method: "GET"
        )!
    }
    
    static func completeRoute(completion: UserRouteCompletionDto) async throws {
        let _: EmptyResponse? = try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "completions/routes",
            method: "POST",
            body: completion
        )
    }
}
