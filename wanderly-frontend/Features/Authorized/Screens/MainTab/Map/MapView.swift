//
//  MapView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 03.05.2025.
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject var viewModel = MapViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            if let bounds = viewModel.cameraBounds {
                
                Map(position: $viewModel.cameraPos, bounds: bounds, interactionModes: [.all]) {
                    if let userLocation = viewModel.userLocation,
                       let city = viewModel.userPreferencesDto?.city,
                       city.contains(coordinate: userLocation) {
                        
                        Annotation("You", coordinate: userLocation) {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(Color(.primary))
                                .font(.title)
                        }
                    }
                    
//                                        ForEach(viewModel.testMarkers) { marker in
//                                            Annotation(marker.name, coordinate: marker.coordinate) {
//                                                Image(systemName: "mappin.circle.fill")
//                                                    .foregroundColor(Color(.primary))
//                                                    .font(.title2)
//                                            }
//                                        }
//                    
//                                        if let route = viewModel.testRoute {
//                                            MapPolyline(coordinates: route.points)
//                                                .stroke(Color(.secondary), lineWidth: 5)
//                                        }
                    
                    
                    if let center = viewModel.routeCenter(),
                       let route = viewModel.latestRoute {
                        Annotation("RouteTapZone", coordinate: center) {
                            Button(action: {
                                viewModel.selectedRoute = RouteWrapper(route: route)
                            }) {
                                Circle()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.clear)
                            }
                        }
                    }
                    
                    if let polyline = viewModel.directionsPolyline {
                        MapPolyline(coordinates: polyline.coordinates)
                            .stroke(.blue, lineWidth: 4)
                    }
                }
                .id(viewModel.cameraKey)
            } else {
                ProgressView()
            }
            
            
            
            HStack {
                Button {
                    viewModel.centerOnUserIfInCity()
                } label: {
                    Image(systemName: "location.fill")
                        .font(.title2)
                        .padding(12)
                        .background(.thinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 3)
                }
                .padding()
                Spacer()
            }
        }
        .sheet(item: $viewModel.selectedRoute) { wrapper in
            let route = wrapper.route
            VStack(spacing: 16) {
                Text("Route Info").font(.title2).bold()
                Text("Distance: \(route.distance / 1000, specifier: "%.2f") km")
                Text("Estimated Time: \(route.expectedTravelTime / 60, specifier: "%.0f") minutes")
                if let min = viewModel.minElevation,
                   let max = viewModel.maxElevation {
                    Text("Elevation Range: \(Int(min)) m – \(Int(max)) m")
                }
                Button("Dismiss") {
                    viewModel.selectedRoute = nil
                }
            }
            .padding()
        }
            .onChange(of: appState.currentCity) { _, newCity in
                if let city = newCity {
                    viewModel.updateCamera(to: city)
                }
            }
            
            .task {
                await viewModel.load()
                viewModel.generateCupertinoTestData()
            }
        }
    
}

#Preview {
    MapView()
        .environmentObject(AppState.shared)
}
