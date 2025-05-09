//
//  MapViewModel.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 03.05.2025.
//
import Foundation
import MapKit
import SwiftUI
import CoreLocation

@MainActor
final class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var markersPerCity: [MarkerDto] = []
    @Published var routesPerCity: [RouteDto] = []
    @Published var drawnRoutesPerCity: [RouteDrawable] = []
    @Published var selectedDrawnRoute: RouteDrawable?
    @Published var selectedMarker: MarkerDto?
    
    @Published var visitedMarkerIndices: [UUID: Int] = [:]
    
    @Published var travelAdvice: TravelAdvice?
    @Published var temperatureCelsius: Double?
    let weatherUtil = WeatherUtil()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var hasLoadedOnce = false
    
    @Published var userPreferencesDto: UserPreferencesDto?
    
    @Published var currentRegion: MKCoordinateRegion? = nil
    @Published var cameraPos: MapCameraPosition = .automatic
    @Published var cameraBounds: MapCameraBounds?
    @Published var cameraKey = UUID()
    
    @Published var userLocation: CLLocationCoordinate2D? = nil
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        configureLocationManager()
    }
    
    func initialLoad() async {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true
        await load()
    }
    
    func load() async {
        isLoading = true;
        defer { isLoading = false }
        
        do {
            print("loading user data...")
            userPreferencesDto = AppState.shared.currentUserPreferences
            markersPerCity = try await GeoService.getMarkers(cityId: userPreferencesDto!.city.id)
            routesPerCity = try await GeoService.getRoutes(cityId: userPreferencesDto!.city.id)
            
            
            for i in 0..<routesPerCity.count {
                let color = Color(
                    hue: Double.random(in: 0.0...0.1),             // 0 = red, ~0.1 = orange
                    saturation: Double.random(in: 0.7...1.0),      // strong color
                    brightness: Double.random(in: 0.4...0.6)       // dark shade
                )
                
                var polylines: [MKPolyline] = []
                var totalDistance: CLLocationDistance = 0
                var totalExpectedTime: TimeInterval = 0
                
                for j in 0..<routesPerCity[i].markers.count - 1 {
                    let startCoord = CLLocationCoordinate2D(
                        latitude: routesPerCity[i].markers[j].latitude,
                        longitude: routesPerCity[i].markers[j].longitude)
                    let endCoord = CLLocationCoordinate2D(
                        latitude: routesPerCity[i].markers[j + 1].latitude,
                        longitude: routesPerCity[i].markers[j + 1].longitude)
                    
                    let request = MKDirections.Request()
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
                    request.transportType = userPreferencesDto?.travelType == .CAR ? .automobile : .walking
                    
                    let directions = MKDirections(request: request)
                    let response = try? await directions.calculate()
                    if let segment = response?.routes.first {
                        polylines.append(segment.polyline)
                        totalDistance += segment.distance
                        totalExpectedTime += segment.expectedTravelTime
                    }
                }
                
                let fullPolyline = MKPolyline(coordinates: polylines.flatMap { $0.coordinates }, count: polylines.flatMap { $0.coordinates }.count)
                drawnRoutesPerCity.append(RouteDrawable(
                    route: routesPerCity[i],
                    polyline: fullPolyline,
                    color: color,
                    totalDistance: totalDistance,
                    expectedTravelTime: totalExpectedTime
                ))
                
            }
            
            // center the camera on city when switching
            configureCamera(for: userPreferencesDto!.city)
            
            //travel advice
            let (temp, advice) = try await weatherUtil.fetchTravelAdvice(
                lat: userPreferencesDto?.city.latitude ?? 0,
                lon: userPreferencesDto?.city.longitude ?? 0
            )
            self.temperatureCelsius = temp
            self.travelAdvice = advice
        } catch {
            self.errorMessage = "Failed to load user data"
            print("Load error: \(error)")
            
            userPreferencesDto = nil
        }
    }
    
    
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // meters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = latest.coordinate
        }
    }
    
    func filteredMarkers() -> [MarkerDto] {
        guard let region = currentRegion else {
            return markersPerCity
        }
        
        // Scale between 10m (zoomed in) and 120m (zoomed out)
        let zoom = region.span.latitudeDelta
        let clampedZoom = min(max(zoom, 0.002), 0.034)
        
        // Linear interpolation between 10 and 120
        let minZoom: Double = 0.002
        let maxZoom: Double = 0.034
        let minDist: Double = 10
        let maxDist: Double = 500
        
        let t = (clampedZoom - minZoom) / (maxZoom - minZoom)
        let dynamicDistance = minDist + t * (maxDist - minDist)
        
        var result: [MarkerDto] = []
        
        for marker in markersPerCity {
            let coordinate = CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude)
            guard region.contains(coordinate) else { continue }
            
            let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            let isTooClose = result.contains { other in
                let otherLoc = CLLocation(latitude: other.latitude, longitude: other.longitude)
                return currentLocation.distance(from: otherLoc) < dynamicDistance
            }
            
            if !isTooClose {
                result.append(marker)
            }
        }
        
        return result
    }
    
    /// Updates the map camera position and bounds manually
    func updateCamera(to city: CityDto) {
        userPreferencesDto?.city = city
        configureCamera(for: city)
    }
    
    /// Central method to configure the camera based on a city
    private func configureCamera(for city: CityDto) {
        if let region = city.regionFromBoundingBox {
            cameraPos = .region(region)
            cameraBounds = MapCameraBounds(
                centerCoordinateBounds: region,
                minimumDistance: 500,
                maximumDistance: 15_000
            )
        } else {
            let coords = CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude)
            cameraPos = .camera(MapCamera(centerCoordinate: coords, distance: 5_000))
            cameraBounds = nil
        }
        
        // Used to reset the map view if needed
        //        cameraKey = UUID()
    }
    
    func scrollToMarker(in routeIndex: Int, markerIndex: Int) {
        guard drawnRoutesPerCity.indices.contains(routeIndex),
              drawnRoutesPerCity[routeIndex].route.markers.indices.contains(markerIndex) else { return }
        
        let marker = drawnRoutesPerCity[routeIndex].route.markers[markerIndex]
        let coordinate = CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude)
        
        withAnimation {
            cameraPos = .camera(
                MapCamera(centerCoordinate: coordinate, distance: 1000)
            )
        }
    }
    
    func showWeather() {
        OverviewState.shared.showToast(travelAdvice == .badWeather ? "Consider car / indoor" : "Consider foot / outdoor")
    }
    
}

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

