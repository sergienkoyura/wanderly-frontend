//
//  StatisticsDto.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 12.05.2025.
//

import Foundation

struct StatisticsDto: Decodable {
    var totalCompletedRoutes: Int
    var totalCompletedARModels: Int
    var totalCompletedMarkers: Int
    var cities: [CityStatisticsDto]
}
