//
//  UserPreferences.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 01.05.2025.
//

import Foundation

struct UserPreferences: Decodable, Encodable {
    var id: UUID? = nil
    var userId: UUID? = nil
    var name: String
    var travelType: TravelType
    var timePerRoute: Int
    var activityType: ActivityType
    var notifications: Bool
    var geoposition: Bool
    var healthKit: Bool
    var cityId: UUID
}
