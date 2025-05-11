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
    @Published var modelsPerCity: [ARModelDto] = []
    @Published var routesPerCity: [RouteDto] = []
    @Published var drawnRoutesPerCity: [RouteDrawable] = []
    
    @Published var visitingMarkerIndices: [UUID: Int] = [:]
    @Published var visitedMarkerIndices: [UUID: Int] = [:]
    
    @Published var travelAdvice: TravelAdvice?
    @Published var temperatureCelsius: Double?
    let weatherUtil = WeatherUtil()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var hasLoadedOnce = false
    
    @Published var isRouteLoading = false
    @Published var selectedRouteForInfo: RouteDrawable?
    @Published var selectedRouteReorderedMarkers: [MarkerDto] = []
    
    @Published var selectedARModel: ARModelDto?

    
    @Published var userPreferencesDto: UserPreferencesDto?
    
    @Published var currentRegion: MKCoordinateRegion? = nil
    @Published var cameraPos: MapCameraPosition = .automatic
    @Published var cameraBounds: MapCameraBounds?
    @Published var cameraKey = UUID()
    
    @Published var userLocation: CLLocationCoordinate2D? = nil
    private let locationManager = CLLocationManager()
    
    private let availableRouteColors: [Color] = [
        Color(hue: 0.15, saturation: 0.85, brightness: 0.65), // yellow-orange
        Color(hue: 0.55, saturation: 0.8, brightness: 0.7),   // teal/cyan
        Color(hue: 0.75, saturation: 0.7, brightness: 0.6),   // purple-blue
        Color(hue: 0.03, saturation: 0.9, brightness: 0.6),   // reddish-orange
        Color(hue: 0.95, saturation: 0.8, brightness: 0.65)   // magenta-pink
    ]

    private var nextColorIndex = 0
    
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = latest.coordinate
        }
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
            modelsPerCity = try await GeoService.getModels(cityId: userPreferencesDto!.city.id)
            routesPerCity = try await GeoService.getRoutes(cityId: userPreferencesDto!.city.id)
            
            try await drawRoutes()
            
            // travel advice
            try await configureWeather()
            
            // configure visited markers in routes
            try await configureVisitedMarkers()
            
            // configure visited markers in routes
            await configureVisitedModels()
            
            // center the camera on city when switching
            configureCamera(for: userPreferencesDto!.city)
        } catch {
            self.errorMessage = "Failed to load user data"
            print("Load error: \(error)")
            
            userPreferencesDto = nil
        }
    }
    
    private func drawRoutes() async throws {
        drawnRoutesPerCity = []
        
        for i in 0..<routesPerCity.count {
            try await drawnRoutesPerCity.append(drawSingleRoute(routesPerCity[i]))
        }
    }
    
    private func drawSingleRoute(_ route: RouteDto) async throws -> RouteDrawable {
        let color = getNextRouteColor()
        
        var polylines: [MKPolyline] = []
        var totalDistance: CLLocationDistance = 0
        var totalExpectedTime: TimeInterval = 0
        
        for j in 0..<route.markers.count - 1 {
            let startCoord = CLLocationCoordinate2D(
                latitude: route.markers[j].latitude,
                longitude: route.markers[j].longitude
            )
            let endCoord = CLLocationCoordinate2D(
                latitude: route.markers[j + 1].latitude,
                longitude: route.markers[j + 1].longitude
            )
            
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
        
        let combined = polylines.flatMap { $0.coordinates }
        let fullPolyline = MKPolyline(coordinates: combined, count: combined.count)
        
        return RouteDrawable(
            route: route,
            polyline: fullPolyline,
            color: color,
            totalDistance: totalDistance,
            expectedTravelTime: totalExpectedTime
        )
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
    
    private func configureWeather() async throws {
        let (temp, advice) = try await weatherUtil.fetchTravelAdvice(
            lat: userPreferencesDto?.city.latitude ?? 0,
            lon: userPreferencesDto?.city.longitude ?? 0
        )
        self.temperatureCelsius = temp
        self.travelAdvice = advice
    }
    
    private func configureVisitedMarkers() async throws {
        for route in routesPerCity {
            await configureVisitedMarkersSingle(route)
        }
    }
    
    private func configureVisitedMarkersSingle(_ route: RouteDto) async {
        do {
            let userRouteCompletion = try await UserService.getCompletionByRouteId(routeId: route.id)
            visitedMarkerIndices[route.id] = userRouteCompletion.step
            // continue exploration or not
            visitingMarkerIndices[route.id] = userRouteCompletion.status == .DONE ?
                                                userRouteCompletion.step :
                                                userRouteCompletion.step + 1
        } catch {
            print("Failed to load completion for route \(route.id): \(error.localizedDescription)")
            visitedMarkerIndices[route.id] = -1
            visitingMarkerIndices[route.id] = 0
        }
    }
    
    private func configureVisitedModels() async {
        for index in modelsPerCity.indices {
            do {
                let completed = try await UserService.getCompletionByModelId(modelId: modelsPerCity[index].id)
                modelsPerCity[index].completed = completed
            } catch {}
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
    
    
    func scrollToMarker(in routeIndex: Int, markerIndex: Int, distance: Double = 1000) {
        guard drawnRoutesPerCity.indices.contains(routeIndex),
              drawnRoutesPerCity[routeIndex].route.markers.indices.contains(markerIndex) else { return }
        
        let marker = drawnRoutesPerCity[routeIndex].route.markers[markerIndex]
        let coordinate = CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude)
        
        withAnimation {
            cameraPos = .camera(
                MapCamera(centerCoordinate: coordinate, distance: distance)
            )
        }
    }
    
    func scrollToCoordinates(_ coordinate: CLLocationCoordinate2D, distance: Double = 1000) {
        withAnimation {
            cameraPos = .camera(
                MapCamera(centerCoordinate: coordinate, distance: distance)
            )
        }
    }

    
    func showWeather() {
        OverviewState.shared.showToast(travelAdvice == .badWeather ? "Consider car / indoor" : "Consider foot / outdoor")
    }
    
    func saveRouteCompletion(routeId: UUID, step: Int, status: RouteStatus = .IN_PROGRESS) {
        Task {
            try await UserService.saveRouteCompletion(completion: UserRouteCompletionDto(status: status, step: step, routeId: routeId))
        }
    }
    
    func deleteRoute(routeId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await GeoService.deleteRouteById(routeId: routeId)
            OverviewState.shared.showToast("Route is deleted")
            
            drawnRoutesPerCity.removeAll { $0.route.id == routeId }
            routesPerCity.removeAll { $0.id == routeId }
            
            let coord = CLLocationCoordinate2D(latitude: userPreferencesDto?.city.latitude ?? 0, longitude:  userPreferencesDto?.city.longitude ?? 0)
            scrollToCoordinates(coord, distance: 5000)
        } catch {
            print("Error deleting route: \(error)")
        }
    }
    
    func addRoute() async {
        isRouteLoading = true;
        defer { isRouteLoading = false }
        do {
            let route = try await GeoService.generateRoute(cityId: userPreferencesDto!.city.id)
            routesPerCity.append(route)
            
            try await drawnRoutesPerCity.append(drawSingleRoute(route))
            
            await configureVisitedMarkersSingle(route)
            
            OverviewState.shared.showToast("Route successfully generated")
        } catch {
            OverviewState.shared.showToast(error.localizedDescription)
        }
    }
    
    func saveEditedRoute() async {
        isRouteLoading = true;
        defer { isRouteLoading = false }
        do {
            selectedRouteForInfo?.route.markers = selectedRouteReorderedMarkers
            
            // Save updated route to backend
            let route = try await GeoService.saveRoute(route: selectedRouteForInfo!.route)

            // Replace in routesPerCity
            if let index = routesPerCity.firstIndex(where: { $0.id == route.id }) {
                routesPerCity[index] = route
            }

            // Replace in drawnRoutesPerCity
            let newDrawable = try await drawSingleRoute(route)
            if let index = drawnRoutesPerCity.firstIndex(where: { $0.route.id == route.id }) {
                drawnRoutesPerCity[index] = newDrawable
            }

            await configureVisitedMarkersSingle(route)
            OverviewState.shared.showToast("Saved")
        } catch {
            OverviewState.shared.showToast(error.localizedDescription)
        }
    }
    
    func getNextRouteColor() -> Color {
        let color = availableRouteColors[nextColorIndex % availableRouteColors.count]
        nextColorIndex += 1
        return color
    }
    
    func branchRoute(routeId: UUID, from: Int) async {
        isRouteLoading = true;
        defer { isRouteLoading = false }
        do {
            // Save updated route to backend
            let route = try await GeoService.branchRoute(routeId: routeId, markerIndex: from)

            // Replace in routesPerCity
            if let index = routesPerCity.firstIndex(where: { $0.id == route.id }) {
                routesPerCity[index] = route
            }

            // Replace in drawnRoutesPerCity
            let newDrawable = try await drawSingleRoute(route)
            if let index = drawnRoutesPerCity.firstIndex(where: { $0.route.id == route.id }) {
                drawnRoutesPerCity[index] = newDrawable
            }

            await configureVisitedMarkersSingle(route)
            OverviewState.shared.showToast("Branched")
        } catch {
            OverviewState.shared.showToast(error.localizedDescription)
        }
    }
    
    func markModelAsCompleted() async {
        do {
            try await GeoService.verifyModel(modelCompletionRequest: ModelCompletionRequest(modelId: selectedARModel!.id, code: selectedARModel!.code))
            
            if let index = modelsPerCity.firstIndex(where: { $0.id == selectedARModel!.id }) {
                modelsPerCity[index].completed = true
            }
            
            selectedARModel = nil

            OverviewState.shared.showToast("Completed")
        } catch {
            OverviewState.shared.showToast(error.localizedDescription)
        }
    }
}
