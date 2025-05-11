//
//  ModelCompletionRequest.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 11.05.2025.
//



import Foundation

struct ModelCompletionRequest: Codable {
    var modelId: UUID
    var code: Int
}
