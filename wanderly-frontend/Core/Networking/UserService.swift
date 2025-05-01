//
//  UserService.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 01.05.2025.
//
import Foundation

enum UserService {
    private static var baseURL: URL { ApiClient.baseURL.appendingPathComponent("preferences") }

    static func checkPreferencesExist(token: String) async throws -> Bool {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "exists",
            method: "GET",
            token: token,
            responseType: Bool.self
        )!
    }

    static func savePreferences(token: String, prefs: UserPreferences) async throws {
        _ = try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "me",
            method: "POST",
            token: token,
            body: prefs,
            responseType: EmptyResponse.self
        )
    }
}
