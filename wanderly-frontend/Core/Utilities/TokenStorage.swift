//
//  TokenStorage.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//


import Foundation

enum TokenStorage {
    private static let accessTokenKey = "access_token"
    private static let refreshTokenKey = "refresh_token"
    
    static func saveAccessToken(_ token: String) {
        KeychainHelper.save(token, forKey: accessTokenKey)
    }
    
    static func saveRefreshToken(_ token: String) {
        KeychainHelper.save(token, forKey: refreshTokenKey)
    }
    
    static func getAccessToken() -> String? {
        KeychainHelper.load(forKey: accessTokenKey)
    }
    
    static func getRefreshToken() -> String? {
        KeychainHelper.load(forKey: refreshTokenKey)
    }
    
    static func clearTokens() {
        KeychainHelper.delete(forKey: accessTokenKey)
        KeychainHelper.delete(forKey: refreshTokenKey)
    }
}
