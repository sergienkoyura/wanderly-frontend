//
//  Untitled.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//

import Foundation

enum AuthService {
    static let baseURL = URL(string: "http://192.168.0.107:9191/api/auth")! // Gateway endpoint
    
    static func login(email: String, password: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("login")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        let customResponse = try JSONDecoder().decode(CustomResponse<AuthResponse>.self, from: data)
        
        if httpResponse.statusCode == 200, let customData = customResponse.data {
            return customData
        } else {
            throw ApiError.serverError(customResponse.message)
        }
    }
    
    static func register(email: String, password: String) async throws {
        let url = baseURL.appendingPathComponent("register")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        let customResponse = try JSONDecoder().decode(CustomResponse<EmptyResponse>.self, from: data)
        
        guard httpResponse.statusCode == 200 else {
            throw ApiError.serverError(customResponse.message)
        }
    }
    
    static func verify(email: String, password: String, code: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("verify-registration")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "email": email,
            "password": password,
            "code": code
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        let customResponse = try JSONDecoder().decode(CustomResponse<AuthResponse>.self, from: data)
        
        if httpResponse.statusCode == 200, let customData = customResponse.data {
            return customData
        } else {
            throw ApiError.serverError(customResponse.message)
        }
    }
    
    //    enum AuthError: LocalizedError {
    //        case invalidCredentials
    //        case serverError(String)
    //
    //        var errorDescription: String? {
    //            switch self {
    //            case .invalidCredentials:
    //                return "Invalid email or password."
    //            case .serverError(let message):
    //                return message
    //            }
    //        }
    //    }
}
