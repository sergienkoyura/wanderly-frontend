//
//  OverviewState.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 03.05.2025.
//


import Foundation
import SwiftUI

@MainActor
class OverviewState: ObservableObject {
    @Published var toastMessage: String?
    
    static let shared = OverviewState()
    private init() {
        
    }
    
    func showToast(_ message: String = "Saved", _ duration: TimeInterval = 2) {
        withAnimation {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation {
                self.toastMessage = nil
               }
        }
    }
}
