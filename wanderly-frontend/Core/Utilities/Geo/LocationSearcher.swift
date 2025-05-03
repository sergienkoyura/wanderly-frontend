//
//  LocationSearcher.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 02.05.2025.
//
import Foundation
import SwiftUI


struct NominatimCityResult: Decodable, Identifiable {
    let place_id: Int
    let display_name: String
    let lat: String
    let lon: String
    let boundingbox: [String]  // [south, north, west, east]
    
    var id: Int { place_id }
    
    var cityName: String {
        display_name.components(separatedBy: ",").first ?? display_name
    }
    
    var city: CityResult {
        CityResult(
            placeId: place_id,
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
    @Published var results: [CityResult] = []
    
    func searchCities(query: String) async {
        guard !query.isEmpty else {
            results = []
            return
        }
        
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://nominatim.openstreetmap.org/search?q=\(encoded)&format=json&limit=5&accept-language=en"
        
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("wanderly-diploma-app/1.0 (sergienkoyura5@gmail.com)", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode([NominatimCityResult].self, from: data)
            results = decoded.map { $0.city }
            print(results)
        } catch {
            print("Nominatim error: \(error)")
        }
    }
}
