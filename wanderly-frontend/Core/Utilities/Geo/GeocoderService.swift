//
//  GeocoderService.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 02.05.2025.
//


import CoreLocation

class GeocoderService {
    static func getCity(from location: CLLocation) async throws -> String {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        return placemarks.first?.locality ?? "Unknown"
    }
}
