import SwiftUI

struct LockScreen: View {
    @ObservedObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isRegistering = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // Logo and title
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.white)

                    Text("StatusVault")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Secure Immigration Document Management")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Login/Register Card
                VStack(spacing: 20) {
                    CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                    CustomSecureField(icon: "lock.fill", placeholder: "Password", text: $password)

                    if isRegistering {
                        CustomSecureField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    Button(action: handleAuth) {
                        Text(isRegistering ? "Create Account" : "Sign In")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }

                    Button(action: {
                        withAnimation {
                            isRegistering.toggle()
                            errorMessage = ""
                        }
                    }) {
                        Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Register")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
                .padding(30)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 30)

                Spacer()
            }
        }
    }

    private func handleAuth() {
        errorMessage = ""

        if isRegistering {
            guard password == confirmPassword else {
                errorMessage = "Passwords do not match"
                return
            }

            guard !email.isEmpty, !password.isEmpty else {
                errorMessage = "Please fill in all fields"
                return
            }

            if authService.register(email: email, password: password) {
                withAnimation {
                    authService.isAuthenticated = true
                }
            } else {
                errorMessage = "Registration failed"
            }
        } else {
            if authService.login(email: email, password: password) {
                withAnimation {
                    authService.isAuthenticated = true
                }
            } else {
                errorMessage = "Invalid email or password"
            }
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 30)

            TextField(placeholder, text: $text)
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding()
        .background(.white.opacity(0.2))
        .cornerRadius(12)
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 30)

            SecureField(placeholder, text: $text)
                .foregroundStyle(.white)
                .textInputAutocapitalization(.never)
        }
        .padding()
        .background(.white.opacity(0.2))
        .cornerRadius(12)
    }
}
