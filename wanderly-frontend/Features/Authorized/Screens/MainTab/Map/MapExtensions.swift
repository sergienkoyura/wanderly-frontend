//
//  MapExtensions.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 09.05.2025.
//

import MapKit

extension MKCoordinateRegion {
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let latMin = center.latitude - span.latitudeDelta / 2
        let latMax = center.latitude + span.latitudeDelta / 2
        let lonMin = center.longitude - span.longitudeDelta / 2
        let lonMax = center.longitude + span.longitudeDelta / 2
        
        return (latMin...latMax).contains(coordinate.latitude) &&
        (lonMin...lonMax).contains(coordinate.longitude)
    }
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: self.pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords
    }
}

// for arrows
extension CLLocationCoordinate2D {
    func bearing(to: CLLocationCoordinate2D) -> Double {
        let fromLat = self.latitude * .pi / 180
        let fromLon = self.longitude * .pi / 180
        let toLat = to.latitude * .pi / 180
        let toLon = to.longitude * .pi / 180
        
        let dLon = toLon - fromLon
        let y = sin(dLon) * cos(toLat)
        let x = cos(fromLat) * sin(toLat) - sin(fromLat) * cos(toLat) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansBearing * 180 / .pi
    }
    
    func midpoint(with: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (self.latitude + with.latitude) / 2,
            longitude: (self.longitude + with.longitude) / 2
        )
    }
    
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2) // in meters
    }
}

extension Array where Element == CLLocationCoordinate2D {
    func sample(every n: Int) -> [(CLLocationCoordinate2D, CLLocationCoordinate2D)] {
        guard self.count >= 2 else { return [] }
        var result: [(CLLocationCoordinate2D, CLLocationCoordinate2D)] = []
        for i in stride(from: 0, to: self.count - 1, by: n) {
            let start = self[i]
            let end = self[Swift.min(i + 1, self.count - 1)]
            result.append((start, end))
        }
        return result
    }
}
