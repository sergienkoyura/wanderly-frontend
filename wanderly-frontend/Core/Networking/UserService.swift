//
//  UserService.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 01.05.2025.
//
import Foundation

enum UserService {
    private static var baseURL: URL { ApiClient.baseURL.appendingPathComponent("user") }

    static func checkPreferencesExist() async throws -> Bool {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "exists",
            method: "GET"
        )!
    }

    static func savePreferences(prefs: UserPreferences) async throws {
        let _: EmptyResponse? = try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "me",
            method: "POST",
            body: prefs
        )
    }
}
