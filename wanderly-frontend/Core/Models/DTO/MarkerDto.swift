//
//  MarkerDto.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 05.05.2025.
//

import Foundation
import SwiftUI

struct MarkerDto: Identifiable, Codable {
    var id: UUID
    var latitude: Double
    var longitude: Double
    var name: String
    var tag: String
    var category: String
    var orderIndex: Int?
    var stayingTime: Int?
    var rating: Double
}

extension MarkerDto {
    func getColor() -> Color {
        switch tag {
        case "PARK", "GARDEN", "NATURE_RESERVE", "VIEWPOINT", "TRAILHEAD":
            return .green
        case "MONUMENT", "MEMORIAL", "CASTLE", "RUINS", "STATUE", "PLACE_OF_WORSHIP", "CHURCH", "MOSQUE", "SYNAGOGUE", "TEMPLE":
            return .brown
        case "MUSEUM", "GALLERY", "THEATRE", "CINEMA", "LIBRARY":
            return .indigo
        case "CAFE", "RESTAURANT", "BAR", "PUB":
            return .orange
        case "ATTRACTION", "THEME_PARK":
            return .pink
        default:
            return .blue
        }
    }
    
    func getIcon() -> String {
        switch tag {
        case "PARK": return "leaf"
        case "GARDEN": return "florinsign.circle"
        case "NATURE_RESERVE": return "tree"
        case "MONUMENT", "MEMORIAL": return "building.columns"
        case "CASTLE": return "building"
        case "RUINS": return "hammer"
        case "STATUE": return "figure.stand"
        case "MUSEUM": return "books.vertical"
        case "GALLERY": return "paintpalette"
        case "PLACE_OF_WORSHIP", "CHURCH", "MOSQUE", "SYNAGOGUE", "TEMPLE": return "cross"
        case "VIEWPOINT": return "binoculars"
        case "TRAILHEAD": return "figure.walk"
        case "ATTRACTION", "THEME_PARK": return "sparkles"
        case "CAFE": return "cup.and.saucer"
        case "RESTAURANT": return "fork.knife"
        case "BAR", "PUB": return "wineglass"
        case "THEATRE": return "theatermasks"
        case "CINEMA": return "film"
        case "LIBRARY": return "books.vertical"
        default: return "mappin"
        }
    }
}

