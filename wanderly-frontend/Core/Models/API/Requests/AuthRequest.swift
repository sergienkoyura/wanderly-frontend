//
//  AuthRequest.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 02.05.2025.
//

struct AuthRequest: Encodable {
    let email: String
    let password: String
    let code: String?
}
