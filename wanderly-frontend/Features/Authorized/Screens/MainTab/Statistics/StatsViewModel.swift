//
//  StatsViewModel.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 12.05.2025.
//
import SwiftUI

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var statistics: StatisticsDto?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadStats() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            statistics = try await UserService.getStatistics()
            print(statistics)
        } catch {
            self.errorMessage = "Failed to load stats: \(error.localizedDescription)"
            print(error)
        }
    }
}
