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
    private init() {}
    
    private var dismissTask: DispatchWorkItem?
    
    func showToast(_ message: String = "Saved", _ duration: TimeInterval = 2) {
        dismissTask?.cancel()
        
        withAnimation {
            toastMessage = message
        }
        
        let task = DispatchWorkItem { [weak self] in
            withAnimation {
                self?.toastMessage = nil
            }
        }
        dismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}
