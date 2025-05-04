//
//  CityResult.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 02.05.2025.
//
import Foundation
import MapKit

struct CityDto: Identifiable, Equatable, Codable {
    var id: UUID? = nil
    var osmId: Int = 0
    var name: String = ""
    var details: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var boundingBox: [Double] = []
}

extension CityDto {
    var regionFromBoundingBox: MKCoordinateRegion? {
        guard boundingBox.count == 4 else { return nil }
        
        let south = boundingBox[0]
        let north = boundingBox[1]
        let west  = boundingBox[2]
        let east  = boundingBox[3]
        
        let center = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: abs(north - south),
            longitudeDelta: abs(east - west)
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        guard boundingBox.count == 4 else { return false }
        let south = boundingBox[0]
        let north = boundingBox[1]
        let west = boundingBox[2]
        let east = boundingBox[3]

        return (south...north).contains(coordinate.latitude) &&
               (west...east).contains(coordinate.longitude)
    }
}
