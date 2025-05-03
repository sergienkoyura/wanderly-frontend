//
//  API.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 01.05.2025.
//
import Foundation

enum ApiClient {
    static let baseURL = URL(string: "http://192.168.0.107:9191/api")!
    
    static func request<T: Decodable>(
        baseURL: URL,
        endpoint: String,
        method: String,
        body: Encodable? = nil,
        injectToken: Bool = true
    ) async throws -> T? {
        return try await authorizedRequest(
            baseURL: baseURL,
            endpoint: endpoint,
            method: method,
            body: body,
            injectToken: injectToken,
            retry: true
        )
    }

    
    private static func authorizedRequest<T: Decodable>(
            baseURL: URL,
            endpoint: String,
            method: String,
            body: Encodable?,
            injectToken: Bool,
            retry: Bool
    ) async throws -> T? {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if injectToken {
            guard let accessToken = TokenStorage.getAccessToken() else {
                throw ApiError.serverError("Token is missing")
            }
            
            print("Access token: \(accessToken)")
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        let decoded = try JSONDecoder().decode(CustomResponse<T>.self, from: data)
        
        if httpResponse.statusCode == 200 {
            return decoded.data
        }
        print(httpResponse.statusCode)
        
        // Handle expired access token
        if httpResponse.statusCode == 401, decoded.status == "error-jwt", retry {
            print("refresh")
            if let newAuth = try? await AuthService.refresh() {
                print("refreshed")
                TokenStorage.saveAccessToken(newAuth.accessToken)
                TokenStorage.saveRefreshToken(newAuth.refreshToken)
                return try await authorizedRequest(
                    baseURL: baseURL,
                    endpoint: endpoint,
                    method: method,
                    body: body,
                    injectToken: true,
                    retry: false // don't retry again
                )
            } else {
                await AppState.shared.logout()
                throw ApiError.serverError("refresh token failed")
            }
        }
        
        throw ApiError.serverError(decoded.message)
    }
}
