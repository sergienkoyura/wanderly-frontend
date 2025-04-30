//
//  AutocompleteCityField.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//
import SwiftUI

struct AutocompleteCityField: View {
    @Binding var city: String
    @State private var suggestions: [String] = ["Kyiv", "Lviv", "Odesa", "Kharkiv"]
    @State private var filtered: [String] = []

    var body: some View {
        VStack(alignment: .leading) {
            TextField("City", text: $city)
                .autocapitalization(.words)
                .onChange(of: city) { old, newValue in
                    filtered = suggestions.filter {
                        $0.lowercased().hasPrefix(newValue.lowercased())
                    }
                }
            
            if !filtered.isEmpty && !city.isEmpty {
                ForEach(filtered.prefix(5), id: \.self) { suggestion in
                    Button(action: {
                        city = suggestion
                        filtered = []
                    }) {
                        Text(suggestion)
                            .foregroundColor(.primary)
                            .padding(.leading, 4)
                    }
                }
            }
        }
    }
}
