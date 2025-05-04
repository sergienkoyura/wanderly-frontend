//
//  AutocompleteCitySheet.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 02.05.2025.
//

import SwiftUI
import CoreLocation

struct AutocompleteCitySheet: View {
    @Binding var city: CityDto
    
    @State private var showSheet = false
    @State private var hasRequestedLocation = false
    @State private var isLoading = false
    
    let locationManager = LocationManager()
    @StateObject private var searcher = LocationSearcher()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("City")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: {
                showSheet = true
                if !hasRequestedLocation {
                    hasRequestedLocation = true
                    
                        Task {
                            if city.name.isEmpty {
                                isLoading = true
                                searcher.query = await locationManager.requestCurrentCity() ?? ""
                                isLoading = false
                            } else {
                                searcher.query = city.name
                            }
                        }
                }
            }) {
                HStack {
                    Text(city.name.isEmpty ? "Select your city" : city.name)
                        .foregroundColor(city.name.isEmpty ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.primary)))
            }
            .background(Color(UIColor.systemGray6))
        }
        .sheet(isPresented: $showSheet) {
            VStack(spacing: 0) {
                Capsule()
                    .frame(width: 36, height: 5)
                    .foregroundColor(Color(.primary))
                    .opacity(0.3)
                    .padding(.top, 12)
                
                NavigationStack {
                    VStack(spacing: 16) {
                        TextField("Search city...", text: $searcher.query)
                            .textFieldStyle(OutlinedTextFieldStyle(isActive: true, isPassword: false))
                            .padding(.horizontal, 16)
                        
                        List {
                            if isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            } else {
                                ForEach(searcher.results) { cityResult in
                                    Button(action: {
                                        city = cityResult
                                        showSheet = false
                                    }) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(cityResult.name)
                                                .font(.body)
                                                .bold()
                                            Text(cityResult.details)
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Choose City")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
}
