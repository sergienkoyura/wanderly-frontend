//
//  CityResult.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 02.05.2025.
//
import Foundation

struct CityDto: Identifiable, Equatable, Decodable, Encodable {
    var id = UUID()
    var placeId: Int = 0
    var name: String = ""
    var details: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var boundingBox: [Double] = []
}
