//
//  BranchRequest.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 10.05.2025.
//
import Foundation

struct BranchRequest: Codable {
    var routeId: UUID
    var markerIndex: Int
}
