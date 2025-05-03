//
//  CustomStyles.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//

import SwiftUI

struct OutlinedTextFieldStyle: TextFieldStyle {
    var isActive = false
    var isPassword = false
    var isPrimary = true;
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .padding(.trailing, isPassword ? 30 : 0)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(isPrimary ? .primary : .secondary), lineWidth: isActive ? 2 : 1)
            )
            .foregroundStyle(.primary)
    }
}


struct ProminentButtonStyle: ButtonStyle {
    var isPrimary = true;
    
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: isEnabled)
    }
    
    private var backgroundColor: Color {
        if !isEnabled {
            return Color(.systemGray4)
        }
        return Color(isPrimary ? .primary : .secondary)
    }
}
