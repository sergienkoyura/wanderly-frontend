//
//  WeatherUtil.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 09.05.2025.
//

import Foundation

enum TravelAdvice: String {
    case badWeather
    case goodWeather
}

struct WeatherResponse: Codable {
    struct Weather: Codable {
        let main: String
        let description: String
    }
    
    struct Main: Codable {
        let temp: Double // in Kelvin
    }
    
    let weather: [Weather]
    let main: Main
}

struct WeatherUtil {
    func fetchTravelAdvice(lat: Double, lon: Double) async throws -> (temperatureCelsius: Double, advice: TravelAdvice) {
        guard let url = URL(string:
                                "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=efcae08d6499375f6016d08afdf36c00&units=metric"
        ) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)
        
        guard let condition = decoded.weather.first?.main else {
            return (decoded.main.temp, .goodWeather)
        }
        
        let badConditions: Set<String> = [
            "Rain", "Drizzle", "Thunderstorm", "Snow", "Extreme", "Fog", "Mist", "Smoke", "Haze", "Dust"
        ]
        
        let advice: TravelAdvice = badConditions.contains(condition) ? .badWeather : .goodWeather
        
        return (decoded.main.temp, advice)
    }
    
}
