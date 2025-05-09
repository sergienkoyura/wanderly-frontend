//
//  UserRouteCompletionDto.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 09.05.2025.
//
import Foundation

struct UserRouteCompletionDto: Codable {
    var status: RouteStatus
    var step: Int
    var routeId: UUID
}
