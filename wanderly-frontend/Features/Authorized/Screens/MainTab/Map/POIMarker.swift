//
//  POIMarker.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 04.05.2025.
//
import MapKit
import Foundation

struct POIMarker: Identifiable {
    enum POIType {
        case greenZone
        case cafe
    }

    let id: UUID
    let type: POIType
    let name: String
    let coordinate: CLLocationCoordinate2D
}
