//
//  UserPreferences.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 01.05.2025.
//

import Foundation

struct UserPreferencesDto: Codable, Equatable {
    var travelType: TravelType
    var timePerRoute: Int
    var activityType: ActivityType
    var city: CityDto
}
