//
//  MapView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 03.05.2025.
//

import SwiftUI
import MapKit

enum MapDisplayMode: String, CaseIterable {
    case markersOnly
    case routesOnlyWithMarkers
    case routesOnlyWithNumbers
    case markersAndRoutes
}

struct MapView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject var viewModel = MapViewModel()
    
    @State private var displayMode: MapDisplayMode = .markersAndRoutes
    @State private var showDropdown = false
    
    @State private var selectedRouteIndex: Int? = nil
    @State private var selectedMarkerIndex: Int = 0
    
    @State private var isPlayingRoute = false
    
    var displayTitle: String {
        switch displayMode {
        case .markersOnly:
            return "Markers Only"
        case .routesOnlyWithMarkers:
            return "Routes Preview"
        case .routesOnlyWithNumbers:
            return "Routes"
        case .markersAndRoutes:
            return "Complete map"
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if let bounds = viewModel.cameraBounds, !viewModel.isLoading {
                ZStack {
                    Map(position: $viewModel.cameraPos, bounds: bounds, interactionModes: [.all], ) {
                        if displayMode != .routesOnlyWithMarkers && displayMode != .routesOnlyWithNumbers {
                            markers()
                        }
                        
                        if displayMode != .markersOnly {
                            routes()
                        }
                    }
                    .mapStyle(.standard(elevation: .flat, pointsOfInterest: .including(), showsTraffic: false))
                    .id(viewModel.cameraKey)
                    .onMapCameraChange { context in
                        viewModel.currentRegion = context.region
                    }
                    .mapControls {
                        MapPitchToggle()
                        // if user is in the city - show his location
                        if let userLocation = viewModel.userLocation,
                           let city = viewModel.userPreferencesDto?.city,
                           city.contains(coordinate: userLocation) {
                            MapUserLocationButton()
                        }
                    }
                    
                    menu()
                    
                    if displayMode == .routesOnlyWithNumbers {
                        routeMenu()
                    }
                }
                
            } else {
                ProgressView()
            }
        }
        .sheet(item: $viewModel.selectedDrawnRoute) { selected in
            VStack(spacing: 16) {
                Text("Route Details").font(.title2).bold()
                Text("Distance: \((selected.totalDistance / 1000).formatted(.number.precision(.fractionLength(2)))) km")
                let totalMinutes = Int((selected.expectedTravelTime / 60).rounded()) + selected.route.avgStayingTime
                Text("Estimated Time: \(totalMinutes) min")
                Text("Travel Time: \(Int((selected.expectedTravelTime / 60).rounded())) min")
                Text("Staying Time: \(selected.route.avgStayingTime) min")
                Text("Counted Time: \(selected.route.avgTime) min")
                Button("Close") {
                    viewModel.selectedDrawnRoute = nil
                }
            }
            .padding()
        }
        .sheet(item: $viewModel.selectedMarker) { selected in
            VStack(spacing: 16) {
                Text("Marker Details").font(.title2).bold()
                Text("Name: \(selected.name)")
                Text("Category: \(selected.category)")
                Text("Tag: \(selected.tag)")
                Text("Order: \(selected.orderIndex ?? 0)")
                Text("Staying time: \(selected.stayingTime ?? 0) min")
                Text("Rating: \(selected.rating.formatted(.number.precision(.fractionLength(2)))) ⭐️")
                Button("Close") {
                    viewModel.selectedMarker = nil
                }
            }
            .padding()
        }
        .onChange(of: appState.currentUserPreferences) { _, newPreferences in
            if let city = newPreferences?.city {
                viewModel.updateCamera(to: city)
                Task {
                    await viewModel.load()
                }
            }
        }
        .onChange(of: displayMode) {_, _ in
            OverviewState.shared.showToast(displayTitle)
        }
        
        //        .task {
        //            await viewModel.initialLoad()
        //        }
    }
    
    @MapContentBuilder
    public func markers() -> some MapContent {
        ForEach(viewModel.filteredMarkers(), id: \.id) { marker in
            Marker(marker.name, systemImage: marker.getIcon(),
                   coordinate: CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude))
            .tint(marker.getColor())
        }
        .annotationTitles(.automatic)
    }
    
    @MapContentBuilder
    public func routes() -> some MapContent {
        ForEach(viewModel.drawnRoutesPerCity, id: \.route.id) { route in
            MapPolyline(coordinates: route.polyline.coordinates)
                .stroke(route.color, lineWidth: 4)
            
            if displayMode == .routesOnlyWithMarkers {
                
                ForEach(route.route.markers, id: \.id) { marker in
                    Marker("\(marker.name) (\(marker.orderIndex ?? 0))", systemImage: marker.getIcon(),
                           coordinate: CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude))
                    .tint(route.color)
                }
            } else {
                //                routeInteractions(for: route)
                routeArrows(for: route)
                
                let visitedUntil = viewModel.visitedMarkerIndices[route.route.id] ?? -1
                
                ForEach(route.route.markers.indices, id: \.self) { i in
                    let marker = route.route.markers[i]
                    let coordinate = CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude)
                    
                    Annotation(marker.name, coordinate: coordinate) {
                        Button {
                            viewModel.selectedMarker = marker
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(i <= visitedUntil ? Color.gray : route.color)
                                    .frame(width: 28, height: 28)
                                    .shadow(radius: 2)
                                
                                Text("\(marker.orderIndex ?? 0)")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.white)
                            }
                            .zIndex(10)
                        }
                    }
                }
            }
        }
    }
    
    
    @MapContentBuilder
    public func routeArrows(for route: RouteDrawable) -> some MapContent {
        
        let arrowCoordinates = route.polyline.coordinates.sample(every: 20)
        
        ForEach(Array(arrowCoordinates.enumerated()), id: \.offset) { index, pair in
            if index % 2 == 1 {
                let start = pair.0
                let end = pair.1
                let angle = start.bearing(to: end)
                let midPoint = start.midpoint(with: end)
                Annotation("", coordinate: midPoint) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(route.color)
                            .frame(width: 15, height: 25)
                            .rotationEffect(.degrees(angle))
                        
                        Image(systemName: "arrowshape.up.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                            .rotationEffect(.degrees(angle))
                    }
                    .zIndex(0)
                }}
        }
        .annotationTitles(.hidden)
    }
    
    
    @MapContentBuilder
    public func routeInteractions(for route: RouteDrawable) -> some MapContent {
        
        let interactionCoordinates = route.polyline.coordinates.sample(every: 20)
        
        ForEach(Array(interactionCoordinates.enumerated()), id: \.offset) { index, pair in
            if index % 2 == 0 {
                let start = pair.0
                let end = pair.1
                let midPoint = start.midpoint(with: end)
                Annotation("", coordinate: midPoint) {
                    Button {
                        viewModel.selectedDrawnRoute = route
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(route.color)
                                .frame(width: 30, height: 20)
                            
                            Image(systemName: "rectangle.and.text.magnifyingglass.rtl")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                        .zIndex(0)
                    }
                }}
        }
        .annotationTitles(.hidden)
        
    }
    
    @ViewBuilder
    public func menu() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                switch displayMode {
                case .markersOnly:
                    displayMode = .routesOnlyWithMarkers
                case .routesOnlyWithMarkers:
                    displayMode = .routesOnlyWithNumbers
                case .routesOnlyWithNumbers:
                    displayMode = .markersAndRoutes
                    selectedRouteIndex = nil
                    selectedMarkerIndex = 0
                case .markersAndRoutes:
                    displayMode = .markersOnly
                }
            } label: {
                Image(systemName: "paintbrush.fill")
                    .dropdownImageStyle()
            }
            .mapDropdownStyle()
            
            Button {
                Task {
                    //                                        await viewModel.generateNewRoute()
                }
                showDropdown = false
            } label: {
                Image(systemName: "plus")
                    .dropdownImageStyle()
            }
            .mapDropdownStyle()
            
            Button {
                Task {
                    viewModel.showWeather()
                }
                showDropdown = false
            } label: {
                Text("\(Int(viewModel.temperatureCelsius ?? 0))°C")
                    .font(.caption)
            }
            .mapDropdownStyle()
        }
        .padding(.top, 4)
        .padding(.leading, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    @ViewBuilder
    public func routeMenu() -> some View {
        VStack {
            Spacer()
            if isPlayingRoute {
                playbackBar()
                    .transition(.move(edge: .bottom))
            } else {
                routeControlBar()
                    .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(.easeInOut, value: isPlayingRoute)
    }
    
    @ViewBuilder
    private func routeControlBar() -> some View {
        HStack(spacing: 16) {
            // [existing route selection + chevrons + ellipsis]
            
            Menu {
                ForEach(viewModel.drawnRoutesPerCity.indices, id: \.self) { index in
                    Button {
                        selectedRouteIndex = index
                        selectedMarkerIndex = 0
                        viewModel.scrollToMarker(in: index, markerIndex: selectedMarkerIndex)
                    } label: {
                        Text("Route \(index + 1)")
                    }
                }
            } label: {
                Label(selectedRouteIndex != nil ? "Route \(selectedRouteIndex! + 1)" : "Select", systemImage: "map")
                    .padding(12)
            }
            
            Spacer()
            
            Button {
                if let index = selectedRouteIndex {
                    selectedMarkerIndex = max(0, selectedMarkerIndex - 1)
                    viewModel.scrollToMarker(in: index, markerIndex: selectedMarkerIndex)
                }
            } label: {
                Image(systemName: "chevron.left").dropdownImageStyle()
            }
            .frame(width: 45, height: 45)
            .disabled(selectedRouteIndex == nil || selectedMarkerIndex == 0)
            
            Button {
                if let index = selectedRouteIndex {
                    let markerCount = viewModel.drawnRoutesPerCity[index].route.markers.count
                    selectedMarkerIndex = min(markerCount - 1, selectedMarkerIndex + 1)
                    viewModel.scrollToMarker(in: index, markerIndex: selectedMarkerIndex)
                }
            } label: {
                Image(systemName: "chevron.right").dropdownImageStyle()
            }
            .frame(width: 45, height: 45)
            .disabled(selectedRouteIndex == nil || viewModel.drawnRoutesPerCity[selectedRouteIndex!].route.markers.count - 1 == selectedMarkerIndex)
            
            Menu {
                Button("Play") {
                    withAnimation {
                        isPlayingRoute = true
                    }
                }
                Button("Info") { /* TBD */ }
                Button("Delete", role: .destructive) { /* TBD */ }
            } label: {
                Image(systemName: "ellipsis").dropdownImageStyle()
            }
            .frame(width: 45, height: 45)
            .disabled(selectedRouteIndex == nil)
        }
        .padding(.vertical, 8)
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .padding(.bottom, 32)
    }
    
    @ViewBuilder
    private func playbackBar() -> some View {
        HStack(spacing: 16) {
            // Route name (left)
            Text("Route \(selectedRouteIndex.map { $0 + 1 } ?? 0)")

            Spacer()

            // Pause button
            Button {
                withAnimation {
                    isPlayingRoute = false
                }
            } label: {
                Image(systemName: "pause.fill").dropdownImageStyle()
            }
            .frame(width: 45, height: 45)

            // Next / Finish button
            Button {
                if let index = selectedRouteIndex {
                    let markerCount = viewModel.drawnRoutesPerCity[index].route.markers.count
                    if selectedMarkerIndex == markerCount - 1 {
                        // finish logic here
                        isPlayingRoute = false
                    } else {
                        let routeId = viewModel.drawnRoutesPerCity[index].route.id
                        viewModel.visitedMarkerIndices[routeId] = selectedMarkerIndex
                        
                        selectedMarkerIndex += 1
                        viewModel.scrollToMarker(in: index, markerIndex: selectedMarkerIndex)
                    }
                }
            } label: {
                Text(selectedMarkerIndex == (selectedRouteIndex.map { viewModel.drawnRoutesPerCity[$0].route.markers.count - 1 } ?? 0) ? "Finish" : "Next")
                    .bold()
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.thickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 8)
        .padding(.bottom, 32)
    }

}

//#Preview {
//    AuthorizedView()
//        .environmentObject(AppState.shared)
//}

extension View {
    func mapDropdownStyle() -> some View {
        self
            .frame(width: 45, height: 45)
            .background(.thickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 1)
    }
}

extension Image {
    func dropdownImageStyle() -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
