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
        token: String? = nil,
        body: Encodable? = nil,
        responseType: T.Type
    ) async throws -> T? {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(CustomResponse<T>.self, from: data)
        
        guard httpResponse.statusCode == 200 else {
            throw ApiError.serverError(decoded.message)
        }
        
        guard let result = decoded.data else {
            return nil
        }

        return result
    }
}
