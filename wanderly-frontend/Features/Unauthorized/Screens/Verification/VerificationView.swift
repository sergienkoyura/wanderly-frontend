//
//  VerificationView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 30.04.2025.
//


import SwiftUI

struct VerificationView: View {
    @StateObject private var viewModel: VerificationViewModel
    
    @State private var remainingSeconds = 60
    @State private var canResend = false
    
    @FocusState private var isFocused: Bool
    
    init(_ email: String, _ password: String) {
        _viewModel = StateObject(wrappedValue: VerificationViewModel(email, password))
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("Enter the verification code sent to:")
                Text(viewModel.email)
                    .bold()
                    .foregroundColor(Color(.secondary))
                    .multilineTextAlignment(.center)
            }
            
            TextField("Verification Code", text: $viewModel.code)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .textFieldStyle(OutlinedTextFieldStyle(isActive: isFocused, isPassword: true, isPrimary: false))
                .submitLabel(.go)
                .onTapGesture {
                    isFocused = true
                }
                .onChange(of: viewModel.code) { old, new in
                    if String(new).count > 6 {
                        viewModel.code = old
                    }
                }
                .onSubmit {
                    verify()
                }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(Color(.error))
                    .font(.footnote)
            }
            
            Button("Verify") {
                verify()
            }
            .buttonStyle(ProminentButtonStyle(isPrimary: false))
            .disabled(viewModel.code.count < 6)

            Button("Resend Code") {
                resend()
            }
            .disabled(!canResend)

            if !canResend {
                Text("You can resend code in \(remainingSeconds)s")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            startTimer()
//            isFocused = true
        }
        .hideKeyboardOnTapOutside()
    }

    func verify() {
        Task {
            await viewModel.verify()
        }
    }

    func resend() {
        // TODO: Call API to resend code
        remainingSeconds = 60
        canResend = false
        startTimer()
    }

    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            remainingSeconds -= 1
            if remainingSeconds <= 0 {
                timer.invalidate()
                canResend = true
            }
        }
    }
}

#Preview {
    VerificationView("sergienkoyura5@gmail.com", "dfgfdgdfgdfg1")
        .environmentObject(AppState.shared)
}
