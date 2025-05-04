//
//  LocationSearcher.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 02.05.2025.
//
import Foundation
import SwiftUI
import Combine

struct NominatimCityResult: Decodable, Identifiable {
    let osm_id: Int
    let display_name: String
    let lat: String
    let lon: String
    let boundingbox: [String]  // [south, north, west, east]
    
    var id: Int { osm_id }
    
    var cityName: String {
        display_name.components(separatedBy: ",").first ?? display_name
    }
    
    var city: CityDto {
        CityDto(
            id: UUID(),
            osmId: osm_id,
            name: cityName,
            details: display_name,
            latitude: Double(lat) ?? 0,
            longitude: Double(lon) ?? 0,
            boundingBox: boundingbox.compactMap(Double.init)
        )
    }
}

@MainActor
class LocationSearcher: ObservableObject {
    @Published var query: String = ""
    @Published var results: [CityDto] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                Task { await self?.searchCities(query: newValue) }
            }
            .store(in: &cancellables)
    }
    
    func searchCities(query: String) async {
        guard !query.isEmpty else {
            results = []
            return
        }
        
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://nominatim.openstreetmap.org/search?city=\(encoded)&format=json&limit=5&accept-language=en"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("wanderly-diploma-app/1.0 (sergienkoyura5@gmail.com)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode([NominatimCityResult].self, from: data)
            results = decoded.map { $0.city }

        } catch {
            print("Nominatim error: \(error)")
        }
    }
}
