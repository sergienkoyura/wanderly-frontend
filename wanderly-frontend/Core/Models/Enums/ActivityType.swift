//
//  ActivityType.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 01.05.2025.
//
import Foundation

enum ActivityType: String, CaseIterable, Decodable, Encodable {
    case INDOOR
    case OUTDOOR
    case COMBINED
}
