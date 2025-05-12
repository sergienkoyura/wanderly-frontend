//
//  CityStatisticsDto.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 12.05.2025.
//
import Foundation

struct CityStatisticsDto: Decodable, Identifiable {
    var name: String
    var inProgressRoutes: Int
    var completedRoutes: Int
    var completedARModels: Int
    
    var id: String { name }
}

extension CityStatisticsDto {
    var progressPercent: Int {
        let cappedRoutes = min(completedRoutes, 5)
        let cappedAR = min(completedARModels, 5)
        let ratio = (Double(cappedRoutes) + Double(cappedAR)) / 10.0
        return Int(ratio * 100)
    }
}
