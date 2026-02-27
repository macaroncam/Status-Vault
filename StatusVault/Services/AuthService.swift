import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUserEmail: String?

    private let emailKey = "userEmail"
    private let passwordKey = "userPassword"

    init() {
        checkAuthStatus()
    }

    var hasExistingAccount: Bool {
        UserDefaults.standard.string(forKey: emailKey) != nil
    }

    func register(email: String, password: String) -> Bool {
        guard !email.isEmpty, !password.isEmpty else { return false }

        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(password, forKey: passwordKey)

        isAuthenticated = true
        currentUserEmail = email
        return true
    }

    func login(email: String, password: String) -> Bool {
        guard let storedEmail = UserDefaults.standard.string(forKey: emailKey),
              let storedPassword = UserDefaults.standard.string(forKey: passwordKey),
              email == storedEmail,
              password == storedPassword else {
            return false
        }

        isAuthenticated = true
        currentUserEmail = email
        return true
    }

    func logout() {
        isAuthenticated = false
        currentUserEmail = nil
    }

    private func checkAuthStatus() {
        if let email = UserDefaults.standard.string(forKey: emailKey) {
            currentUserEmail = email
        }
    }
}
