//
//  RouteDrawable.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 06.05.2025.
//

import MapKit
import SwiftUI

struct RouteDrawable: Identifiable {
//    var route: MKRoute
    var id = UUID()
    var route: RouteDto
    var polyline: MKPolyline
    var color: Color
    let totalDistance: CLLocationDistance // meters
    let expectedTravelTime: TimeInterval // seconds
}
