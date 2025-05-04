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
    @Published var selectedRoute: RouteWrapper?
    @Published var directionsPolyline: MKPolyline?
    @Published var routeTransportType: MKDirectionsTransportType = .automobile
    
    @Published var testMarkers: [Marker] = []
    @Published var testRoute: GeneratedRoute?
    
    @Published var latestRoute: MKRoute?
    
    @Published var minElevation: Double?
    @Published var maxElevation: Double?
    
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    private var hasLoadedOnce = false

    @Published var userPreferencesDto: UserPreferencesDto?
    
    @Published var cameraPos: MapCameraPosition = .automatic
    @Published var cameraBounds: MapCameraBounds?
    @Published var cameraKey = UUID()
    
    @Published var userLocation: CLLocationCoordinate2D? = nil
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        configureLocationManager()
    }
    
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // meters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func generateCupertinoTestData() {
        let sampleCoords: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.322998, longitude: -122.032182), // Apple HQ
            CLLocationCoordinate2D(latitude: 37.3230, longitude: -122.0300),
            CLLocationCoordinate2D(latitude: 37.3215, longitude: -122.0295),
            CLLocationCoordinate2D(latitude: 37.3240, longitude: -122.0275),
            CLLocationCoordinate2D(latitude: 37.3255, longitude: -122.0308),
        ]
        
        testMarkers = sampleCoords.enumerated().map { i, coord in
            Marker(name: "Marker \(i+1)", coordinate: coord)
        }
        
        testRoute = GeneratedRoute(points: sampleCoords)
        
        calculateRoute(from: sampleCoords, transportType: routeTransportType)
    }
    
    func calculateRoute(from points: [CLLocationCoordinate2D], transportType: MKDirectionsTransportType) {
        guard points.count >= 2 else { return }
        var routes: [MKRoute] = []
        var polylines: [MKPolyline] = []

        Task {
            for i in 0..<points.count - 1 {
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: points[i]))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: points[i + 1]))
                request.transportType = transportType

                let directions = MKDirections(request: request)
                let response = try? await directions.calculate()
                if let route = response?.routes.first {
                    routes.append(route)
                    polylines.append(route.polyline)
                }
            }

            // Combine all polylines into one
            let fullPolyline = MKPolyline(coordinates: polylines.flatMap { $0.coordinates }, count: polylines.flatMap { $0.coordinates }.count)
            
            DispatchQueue.main.async {
//                self.selectedRoute?.route = routes.first! // OR custom route summary
                self.latestRoute = routes.first
                
                self.directionsPolyline = fullPolyline
                
                let elevations = fullPolyline.coordinates.map {
                    CLLocation(latitude: $0.latitude, longitude: $0.longitude).altitude
                }
                
                self.minElevation = elevations.min()
                self.maxElevation = elevations.max()
                
                // possible to add elevations via open-elevation api
            }
        }
    }



    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = latest.coordinate
        }
    }
    
    func centerOnUserIfInCity() {
        guard let userLocation = userLocation,
              let city = userPreferencesDto?.city,
              city.contains(coordinate: userLocation) else {
            OverviewState.shared.showToast("User is outside the city")
            return
        }

        withAnimation {
            cameraPos = .camera(MapCamera(centerCoordinate: userLocation, distance: 2500))
        }
    }
    
    func load() async {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true
        
        isLoading = true;
        defer { isLoading = false }
        
        print("loading user data...")
        
        do {
            let prefs = try await UserService.me()
            userPreferencesDto = prefs
            configureCamera(for: prefs.city)
        } catch {
            self.errorMessage = "Failed to load user data"
            print("Load error: \(error)")
            
            userPreferencesDto = nil
        }
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
        cameraKey = UUID()
    }
    
    
    func routeCenter() -> CLLocationCoordinate2D? {
        guard let polyline = directionsPolyline else { return nil }
        let coords = polyline.coordinates
        guard !coords.isEmpty else { return nil }

        let avgLat = coords.map(\.latitude).reduce(0, +) / Double(coords.count)
        let avgLon = coords.map(\.longitude).reduce(0, +) / Double(coords.count)
        return CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)
    }
}


struct Marker: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

struct GeneratedRoute: Identifiable {
    let id = UUID()
    let points: [CLLocationCoordinate2D]
}

struct RouteWrapper: Identifiable {
    let id = UUID()
    var route: MKRoute
}

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: .init(), count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
