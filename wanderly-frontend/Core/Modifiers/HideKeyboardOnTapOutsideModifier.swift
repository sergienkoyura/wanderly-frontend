//
//  HideKeyboardOnTapOutsideModifier.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//


import SwiftUI

struct HideKeyboardOnTapOutsideModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
            )
    }
}

extension View {
    func hideKeyboardOnTapOutside() -> some View {
        modifier(HideKeyboardOnTapOutsideModifier())
    }
}
