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
    case routesOnlyWithNumbers
    case arModels
    case completeMap
}

struct MapView: View {
    @ObservedObject private var watchManager = WatchSessionManager.shared
    @EnvironmentObject private var appState: AppState
    @StateObject var viewModel = MapViewModel()
    
    @State private var displayMode: MapDisplayMode = .routesOnlyWithNumbers
    @State private var showDropdown = false
    
    @State private var selectedRouteIndex: Int? = nil
    @State private var selectedMarkerIndex: Int = 0
    
    @State private var isPlayingRoute = false
    @State private var focusMode = false
    
    @State private var hasEdited = false
    
    @State private var isShowingARCamera = false

    
    var displayTitle: String {
        switch displayMode {
        case .markersOnly:
            return "Markers"
        case .routesOnlyWithNumbers:
            return "Routes"
        case .arModels:
            return "Models"
        case .completeMap:
            return "Complete map"
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            if let bounds = viewModel.cameraBounds, !viewModel.isLoading {
                ZStack {
                    Map(position: $viewModel.cameraPos, bounds: bounds, interactionModes: [.all], ) {
                        switch displayMode {
                        case .markersOnly:
                            markers()
                        case .routesOnlyWithNumbers:
                            routes()
                        case .arModels:
                            arZones()
                        case .completeMap:
                            markers()
                            routes()
                            arZones()
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
        .sheet(item: $viewModel.selectedRouteForInfo, onDismiss: {
            hasEdited = false
        }) { route in
            RouteInfoSheet(
                route: route,
                reorderedMarkers: $viewModel.selectedRouteReorderedMarkers,
                routeIndex: selectedRouteIndex ?? 0,
                hasEdited: $hasEdited,
                onClose: {
                    viewModel.selectedRouteForInfo = nil
                },
                onRegenerate: {
                    await viewModel.saveEditedRoute()
                    viewModel.selectedRouteForInfo = nil
                },
                onBranch: { markerIndex in
                    await viewModel.branchRoute(routeId: route.route.id, from: markerIndex)
                    viewModel.selectedRouteForInfo = nil
                }
            )
            .onAppear {
                viewModel.selectedRouteReorderedMarkers = route.route.markers
            }
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $isShowingARCamera) {
            if let model = viewModel.selectedARModel {
                ARVerificationView(code: model.code) {
                    // call backend to verify here (e.g., via `viewModel.verifyARModel(id:)`)
                    await viewModel.markModelAsCompleted()
                    isShowingARCamera = false
                }
            }
        }
        .onChange(of: appState.currentUserPreferences) { _, newPreferences in
            if let city = newPreferences?.city {
                viewModel.updateCamera(to: city)
                Task {
                    await viewModel.load()
                    selectedRouteIndex = nil
                    selectedMarkerIndex = 0
                    focusMode = false
                    isPlayingRoute = false
                }
            }
        }
        .onChange(of: displayMode) {_, _ in
            OverviewState.shared.showToast(displayTitle)
        }
        .onChange(of: watchManager.isNextCalled) { _, newValue in
            guard newValue else { return }

            // Run the same logic as tapping "Next"
            if let routeIndex = selectedRouteIndex {
                let routeId = viewModel.drawnRoutesPerCity[routeIndex].route.id
                if let visitingIndex = viewModel.visitingMarkerIndices[routeId] {
                    let markerCount = viewModel.drawnRoutesPerCity[routeIndex].route.markers.count

                    if visitingIndex == markerCount - 1 {
                        isPlayingRoute = false
                        viewModel.scrollToMarker(in: routeIndex, markerIndex: visitingIndex, distance: 3500)
                        viewModel.visitedMarkerIndices[routeId] = visitingIndex
                        viewModel.saveRouteCompletion(routeId: routeId, step: visitingIndex, status: .DONE)
                        watchManager.sendRouteStatus(routeIndex: 0, isPlaying: false)
                    } else {
                        viewModel.visitedMarkerIndices[routeId] = visitingIndex
                        viewModel.saveRouteCompletion(routeId: routeId, step: visitingIndex)
                        viewModel.visitingMarkerIndices[routeId] = visitingIndex + 1
                        viewModel.scrollToMarker(in: routeIndex, markerIndex: visitingIndex + 1)
                        watchManager.sendRouteUpdate(routeIndex: routeIndex + 1, step: visitingIndex + 1, totalSteps: markerCount)
                    }
                }
            }

            // Reset the flag
            watchManager.isNextCalled = false
        }
        .onAppear {
            watchManager.sendRouteStatus(routeIndex: 0, isPlaying: false)
        }
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
        ForEach(viewModel.drawnRoutesPerCity.indices, id: \.self) { routeIndex in
            let route = viewModel.drawnRoutesPerCity[routeIndex]
            
            if (!isPlayingRoute && !focusMode || (isPlayingRoute || focusMode) && viewModel.drawnRoutesPerCity[selectedRouteIndex ?? 0].route.id == route.route.id) {
                MapPolyline(coordinates: route.polyline.coordinates)
                    .stroke(route.color, lineWidth: 4)
                
                let visitedUntil = viewModel.visitedMarkerIndices[route.route.id] ?? -1
                routeArrows(for: route)
                
                ForEach(route.route.markers.indices, id: \.self) { i in
                    let marker = route.route.markers[i]
                    let coordinate = CLLocationCoordinate2D(latitude: marker.latitude, longitude: marker.longitude)
                    
                    Annotation(marker.name, coordinate: coordinate) {
                        Button {
                            selectedRouteIndex = routeIndex
                            selectedMarkerIndex = i
                            viewModel.scrollToMarker(in: routeIndex, markerIndex: selectedMarkerIndex)
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
            }
        }
        .annotationTitles(.hidden)
    }
    
    @MapContentBuilder
    public func arZones() -> some MapContent {
        ForEach(viewModel.modelsPerCity) { model in
            
            let center = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)
            
            MapCircle(center: center, radius: 150) // radius is in meters; 150m radius = 300m diameter
                .foregroundStyle(
                    model.completed ?? false ? .gray.opacity(0.4) : Color.accentColor.opacity(0.4)
                )
            if !(model.completed ?? false) {
                Annotation("", coordinate: center) {
                    Button{
                        viewModel.selectedARModel = model
                        isShowingARCamera = true
                    } label: {
                        Label("AR Zone", systemImage: "arkit")
                            .padding(8)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    public func menu() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !isPlayingRoute {
                Button {
                    switch displayMode {
                    case .markersOnly:
                        displayMode = .routesOnlyWithNumbers
                    case .routesOnlyWithNumbers:
                        displayMode = .arModels
                        selectedRouteIndex = nil
                        selectedMarkerIndex = 0
                        focusMode = false
                    case .arModels:
                        displayMode = .completeMap
                    case .completeMap:
                        displayMode = .markersOnly
                    }
                } label: {
                    Image(systemName: "paintbrush.fill")
                        .dropdownImageStyle()
                }
                .mapDropdownStyle()
                
                Button {
                    Task {
                        await viewModel.addRoute()
                    }
                    showDropdown = false
                } label: {
                    if viewModel.isRouteLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "plus")
                            .dropdownImageStyle()
                    }
                }
                .disabled(viewModel.isRouteLoading)
                .mapDropdownStyle()
                
            }
            
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
                focusMode.toggle()
            } label: {
                Image(systemName: focusMode ? "eye.slash" : "eye")
                    .dropdownImageStyle()
            }
            .frame(width: 50, height: 45)
            .disabled(selectedRouteIndex == nil)
            
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
            
            
            if let index = selectedRouteIndex {
                let currentRoute = viewModel.drawnRoutesPerCity[index].route
                let completed = viewModel.visitedMarkerIndices[currentRoute.id] == viewModel.visitingMarkerIndices[currentRoute.id]
                Menu {
                    Button(completed ? "Completed" : "Play") {
                        withAnimation {
                            isPlayingRoute = true
                            viewModel.scrollToMarker(in: index, markerIndex: viewModel.visitingMarkerIndices[currentRoute.id] ?? 0)
                            
                            watchManager.sendRouteUpdate(
                                routeIndex: index + 1,
                                step: (viewModel.visitedMarkerIndices[currentRoute.id] ?? 0) + 1,
                                totalSteps: viewModel.drawnRoutesPerCity[index].route.markers.count
                            )
                        }
                    }.disabled(completed)
                    Button("Info") {
                        if let index = selectedRouteIndex {
                            viewModel.selectedRouteForInfo = viewModel.drawnRoutesPerCity[index]
                        }
                    }
                    Button("Delete", role: .destructive) {
                        Task {
                            selectedRouteIndex = nil
                            selectedMarkerIndex = 0
                            focusMode = false
                            
                            await viewModel.deleteRoute(routeId: currentRoute.id)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis").dropdownImageStyle()
                }
                .frame(width: 45, height: 45)
                .disabled(selectedRouteIndex == nil)
            }
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
                watchManager.sendRouteStatus(
                    routeIndex: 0,
                    isPlaying: false
                )
            } label: {
                Image(systemName: "pause.fill").dropdownImageStyle()
            }
            .frame(width: 45, height: 45)
            
            // Next / Finish button
            if let routeIndex = selectedRouteIndex {
                let routeId = viewModel.drawnRoutesPerCity[routeIndex].route.id
                if let visitingIndex = viewModel.visitingMarkerIndices[routeId] {
                    Button {
                        let markerCount = viewModel.drawnRoutesPerCity[routeIndex].route.markers.count
                        
                        if visitingIndex == markerCount - 1 {
                            isPlayingRoute = false
                            viewModel.scrollToMarker(in: routeIndex, markerIndex: visitingIndex, distance: 3500)
                            
                            viewModel.visitedMarkerIndices[routeId] = visitingIndex
                            viewModel.saveRouteCompletion(routeId: routeId, step: visitingIndex, status: .DONE)
                            
                            watchManager.sendRouteStatus(routeIndex: 0, isPlaying: false)
                        } else {
                            viewModel.visitedMarkerIndices[routeId] = visitingIndex
                            viewModel.saveRouteCompletion(routeId: routeId, step: visitingIndex)
                            
                            viewModel.visitingMarkerIndices[routeId] = visitingIndex + 1
                            viewModel.scrollToMarker(in: routeIndex, markerIndex: visitingIndex + 1)
                            
                            watchManager.sendRouteUpdate(routeIndex: routeIndex + 1, step: visitingIndex + 1, totalSteps: markerCount)
                        }
                        
                    } label: {
                        Text(viewModel.visitingMarkerIndices[routeId] == (selectedRouteIndex.map { viewModel.drawnRoutesPerCity[$0].route.markers.count - 1 } ?? 0) ? "Finish" : "Next")
                            .bold()
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor))
                    }.foregroundColor(.white)
                }
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
