//
//  ARModelDto.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 11.05.2025.
//
import Foundation

struct ARModelDto: Identifiable, Codable {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var code: Int
    var completed: Bool? = false
}
