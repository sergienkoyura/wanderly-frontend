//
//  RegisterView.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 29.04.2025.
//

import SwiftUI

struct RegisterView: View {
    @ObservedObject var viewModel: UnauthorizedViewModel
    
    @State private var isPasswordVisible = false
    
    @FocusState private var focusedField: Field?
    
    var body: some View {
//        NavigationStack {
            
            VStack(spacing: 24) {
                Spacer()
                
                Text("Create an account")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color(.secondary))
                
                VStack(spacing: 16) {
                    TextField("Email", text: $viewModel.email, axis: .vertical)
                        .focused($focusedField, equals: .email)
                        .textFieldStyle(OutlinedTextFieldStyle(isActive: focusedField == .email, isPassword: false, isPrimary: false))
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
                            .textFieldStyle(OutlinedTextFieldStyle(isActive: focusedField == .password, isPassword: true, isPrimary: false))
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
                            .textFieldStyle(OutlinedTextFieldStyle(isActive: focusedField == .password, isPassword: true, isPrimary: false))
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
                        Text("Register")
                    }
                }
                .buttonStyle(ProminentButtonStyle(isPrimary: false))
                .disabled(viewModel.isLoading)
                
                Spacer()
                
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(Color(.placeholder))
                    Button("Login") {
                        viewModel.switchTo(flow: .login)
                    }
                    .foregroundColor(Color(.secondary))
                    .bold()
                }
                .font(.footnote)
            }
            .padding(.horizontal, 24)
            
            
//            .navigationDestination(isPresented: $viewModel.showVerification, destination: {
//                VerificationView(
//                    viewModel: VerificationViewModel(
//                        viewModel.email,
//                        viewModel.password
//                    )
//                )
//            })
//        }
    }
    
    func submit() {
        Task {
            await viewModel.register()
        }
    }
}
