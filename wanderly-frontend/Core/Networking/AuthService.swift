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
            body: AuthRequest(email: email, password: password, code: nil),
            injectToken: false
        )!
    }
    
    static func register(email: String, password: String) async throws {
        let _: EmptyResponse? = try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "register",
            method: "POST",
            body: AuthRequest(email: email, password: password, code: nil),
            injectToken: false
        )
    }
    
    static func verify(email: String, password: String, code: String) async throws -> AuthResponse {
        try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "verify-registration",
            method: "POST",
            body: AuthRequest(email: email, password: password, code: code),
            injectToken: false
        )!
    }
    
    static func refresh() async throws -> AuthResponse {
        print("refresh token is \(TokenStorage.getRefreshToken() ?? "")")
        return try await ApiClient.request(
            baseURL: baseURL,
            endpoint: "refresh-token",
            method: "POST",
            body: ["refreshToken": TokenStorage.getRefreshToken() ?? ""],
            injectToken: false
        )!
    }
}
