//
//  WatchConnectivityManager.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 11.05.2025.
//
import WatchConnectivity

final class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var routeIndex = 0
    @Published var isPlayingRoute = false
    @Published var currentStep = 0
    @Published var totalSteps = 1

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.routeIndex = message["routeIndex"] as? Int ?? 0
            self.isPlayingRoute = message["isPlaying"] as? Bool ?? false
            self.currentStep = message["currentStep"] as? Int ?? 0
            self.totalSteps = message["totalSteps"] as? Int ?? 1
            
        }
    }
    
    func sendNextStep() {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["action": "nextStep"], replyHandler: nil)
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("Watch session activation failed with error: \(error.localizedDescription)")
        } else {
            print("Watch session activated with state: \(activationState.rawValue)")
        }
    }
}
