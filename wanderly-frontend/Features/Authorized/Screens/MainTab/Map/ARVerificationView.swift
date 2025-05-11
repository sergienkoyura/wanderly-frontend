//
//  ARVerificationView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 11.05.2025.
//
import SwiftUI

struct ARVerificationView: View {
    let code: Int
    let onVerify: () async -> Void

    @State private var enteredCode: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(code: code)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 12) {
                Text("Enter the number above to verify")
                    .font(.headline)
                    .foregroundStyle(.accent)
                    .padding(.top, 8)

                TextField("0000", text: $enteredCode)
                    .keyboardType(.numberPad)
                    .focused($isFocused)
                    .multilineTextAlignment(.center)
                    .onChange(of: enteredCode) { _, newValue in
                        // allow only numbers and 4 digits max
                        enteredCode = String(newValue.prefix(4).filter(\.isNumber))
                        showError = false
                    }
                    .onTapGesture {
                        isFocused = true
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(Color(.primary)))
                    .padding(.horizontal)

                if showError {
                    Text("Code doesn't match. Try again")
                        .foregroundColor(.red)
                        .font(.footnote)
                }

                Button("Verify") {
                    isFocused = false
                    if enteredCode == String(format: "%04d", code) {
                        Task {
                            isLoading = true
                            await onVerify()
                            isLoading = false
                        }
                    } else {
                        showError = true
                    }
                }
                .disabled(isLoading || enteredCode.count < 4)
                .buttonStyle(ProminentButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(.white)
            .cornerRadius(12)
            .padding()
            .hideKeyboardOnTapOutside()
        }
    }
}
