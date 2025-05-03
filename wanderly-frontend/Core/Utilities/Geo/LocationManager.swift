//
//  LocationManager.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 02.05.2025.
//


import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    private var onLocationUpdate: ((CLLocation?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        onLocationUpdate = completion
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.requestLocation()
    }
    
    func requestCurrentCity() async -> String? {
        let status = manager.authorizationStatus

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()

            while manager.authorizationStatus == .notDetermined {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }

        let updatedStatus = manager.authorizationStatus

        guard updatedStatus == .authorizedWhenInUse || updatedStatus == .authorizedAlways else {
            print("User denied location permission.")
            return nil
        }

        return await withCheckedContinuation { continuation in
            requestLocation { location in
                guard let location = location else {
                    print("Location access failed.")
                    continuation.resume(returning: nil)
                    return
                }

                Task {
                    do {
                        let cityName = try await GeocoderService.getCity(from: location)
                        continuation.resume(returning: cityName)
                    } catch {
                        print("Reverse geocoding failed: \(error)")
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        onLocationUpdate?(locations.first)
        onLocationUpdate = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocationUpdate?(nil)
        onLocationUpdate = nil
    }
}
