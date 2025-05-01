//
//  Untitled.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//

import Foundation

enum AuthService {
    private static var baseURL: URL { ApiClient.baseURL.appendingPathComponent("auth") }
    
    static func login(email: String, password: String) async throws -> AuthResponse {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "login",
            method: "POST",
            body: ["email": email, "password": password],
            responseType: AuthResponse.self
        )!
    }
    
    static func register(email: String, password: String) async throws {
        _ = try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "register",
            method: "POST",
            body: ["email": email, "password": password],
            responseType: EmptyResponse.self
        )
    }
    
    static func verify(email: String, password: String, code: String) async throws -> AuthResponse {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "verify-registration",
            method: "POST",
            body: ["email": email, "password": password, "code": code],
            responseType: AuthResponse.self
        )!
    }
}
