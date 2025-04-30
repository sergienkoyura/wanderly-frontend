//
//  LoginView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: UnauthorizedViewModel
    
    @State private var isPasswordVisible = false
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
        
        VStack(spacing: 24) {
            Spacer()
            
            Text("Welcome Back")
                .font(.title)
                .bold()
                .foregroundColor(Color(.primary))
            
            VStack(spacing: 16) {
                TextField("Email", text: $viewModel.email, axis: .vertical)
                    .focused($focusedField, equals: .email)
                    .textFieldStyle(OutlinedTextFieldStyle(isActive: focusedField == .email, isPassword: false))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .submitLabel(.next)
                // to switch the input efficiently
                    .onChange(of: viewModel.email) { old, newValue in
                        guard focusedField == .email else { return }
                        guard newValue.contains("\n") else { return }
                        viewModel.email = newValue.replacing("\n", with: "")
                        focusedField = .password
                    }
                    .onTapGesture {
                        focusedField = .email
                    }
                
                ZStack(alignment: .trailing) {
                    
                    TextField("Password", text: $viewModel.password)
                        .focused($focusedField, equals: .password)
                        .textFieldStyle(OutlinedTextFieldStyle(isActive: focusedField == .password, isPassword: true))
                        .submitLabel(.go)
                        .opacity(isPasswordVisible ? 1 : 0)
                        .zIndex(1)
                        .onSubmit {
                            submit()
                        }
                        .onTapGesture {
                            focusedField = .password
                        }
                    
                    SecureField("Password", text: $viewModel.password)
                        .focused($focusedField, equals: .password)
                        .textFieldStyle(OutlinedTextFieldStyle(isActive: focusedField == .password, isPassword: true))
                        .submitLabel(.go)
                        .opacity(isPasswordVisible ? 0 : 1)
                        .zIndex(1)
                        .onSubmit {
                            submit()
                        }
                        .onTapGesture {
                            focusedField = .password
                        }
                    
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                            .padding(12)
                    }
                    .zIndex(10)
                }
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(Color(.error))
                    .font(.footnote)
            }
            
            Button(action: {
                submit()
                focusedField = nil
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Login")
                }
            }
            .buttonStyle(ProminentButtonStyle())
            .disabled(viewModel.isLoading)
            
            Spacer()
            
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(Color(.placeholder))
                Button("Register") {
                    viewModel.switchTo(flow: .register)
                }
                .foregroundColor(Color(.primary))
                .bold()
            }
            .font(.footnote)
        }
        .padding(.horizontal, 24)
        
    }
    
    func submit() {
        Task {
            await viewModel.login()
        }
    }
}

#Preview {
    RegisterView(viewModel: UnauthorizedViewModel())
        .environmentObject(AppState.shared)
}
