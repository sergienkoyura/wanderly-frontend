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
    
    func showToast(_ message: String, duration: TimeInterval = 2) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.toastMessage = nil
        }
    }
}
