//
//  RouteDto.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 05.05.2025.
//


import Foundation
import MapKit

struct RouteDto: Codable {
    var id: UUID
    var category: String
    var avgTime: Int
    var markers: [MarkerDto]
}

extension RouteDto {
    var avgStayingTime: Int {
        markers.map { $0.stayingTime ?? 0 }.reduce(0, +)
    }
}
