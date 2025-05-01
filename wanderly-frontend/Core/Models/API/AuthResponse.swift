//
//  AuthResponse.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//

struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
}
