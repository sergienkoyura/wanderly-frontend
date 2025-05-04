//
//  SettingsView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 03.05.2025.
//

import SwiftUI

struct SettingsView: View {
    var onSave: () -> Void
    
    @StateObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var appState: AppState
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    SettingsView()
}
