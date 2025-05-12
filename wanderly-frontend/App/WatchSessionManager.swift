//
//  WatchSessionManager.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 11.05.2025.
//
import WatchConnectivity

final class WatchSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSessionManager()
    
    @Published var isNextCalled = false
    
    private override init() {
        super.init()
        activateSession()
    }
    
    private func activateSession() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendRouteStatus(routeIndex: Int, isPlaying: Bool) {
        print("Got route status to send to watch: \(routeIndex), \(isPlaying)")
        
        if WCSession.default.isReachable {
            print("Watch is reachable, sending message")
            WCSession.default.sendMessage([
                "routeIndex": routeIndex,
                "isPlaying": isPlaying
            ], replyHandler: nil)
        }
    }
    
    func sendRouteUpdate(routeIndex: Int, step: Int, totalSteps: Int) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage([
                "routeIndex": routeIndex,
                "currentStep": step,
                "totalSteps": totalSteps,
                "isPlaying": true
            ], replyHandler: nil)
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate() // Important for handoff
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let action = message["action"] as? String, action == "nextStep" {
                self.isNextCalled = true
            }
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
