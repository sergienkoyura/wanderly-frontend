//
//  StatisticsView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 03.05.2025.
//

import SwiftUI


struct StatsView: View {
    @StateObject var viewModel = StatsViewModel()
    
    var body: some View {
        ZStack {
            if let stats = viewModel.statistics {
                
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Progress")
                                .font(.title)
                                .bold()
                                .foregroundColor(Color(.primary))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Total completed routes: \(stats.totalCompletedRoutes)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Text("Total completed AR Zones: \(stats.totalCompletedARModels)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Overall Progress")
                                .font(.title3)
                                .bold()
                                .foregroundColor(Color(.primary))
                            
                            ForEach(stats.cities) { city in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(city.name)
                                            .font(.headline)
                                            .bold()
                                        Spacer()
                                        Text("\(city.progressPercent)%")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(Color.accentColor)
                                            )
                                    }
                                    
                                    ZStack(alignment: .leading) {
                                        GeometryReader { geometry in
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(Color.gray.opacity(0.15))
                                                .frame(height: 14)
                                            
                                            RoundedRectangle(cornerRadius: 7)
                                                .fill(LinearGradient(colors: [Color.accentColor, Color.blue], startPoint: .leading, endPoint: .trailing))
                                                .frame(width: geometry.size.width * CGFloat(city.progressPercent) / 100, height: 14)
                                        }
                                        .frame(height: 14)
                                    }
                                    
                                    Text("Routes: \(city.completedRoutes) completed, \(city.inProgressRoutes) in progress")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("AR Zones: \(city.completedARModels) completed")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Divider()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .background(Color.white.ignoresSafeArea())
                    .navigationBarBackButtonHidden()
                }
            } else if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadStats()
        }
    }
}


#Preview {
    AuthorizedView()
        .environmentObject(AppState.shared)
}
