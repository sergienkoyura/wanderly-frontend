//
//  UserSessionViewModel.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 04.05.2025.
//


@MainActor
class AuthorizedViewModel: ObservableObject {
    @Published var user: UserDto?
    @Published var preferences: UserPreferencesDto?
    @Published var isLoading = true
    @Published var errorMessage: String?

    func load() async {
        do {
            self.user = try await AuthService.me()
            self.preferences = try await UserService.me()
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to load user data"
            self.isLoading = false
        }
    }
}
