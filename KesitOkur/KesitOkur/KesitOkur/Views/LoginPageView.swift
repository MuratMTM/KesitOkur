struct LoginPageView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Your existing gradient background
                
                VStack(spacing: 20) {
                    // Email/Password fields
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // Sign In/Up Button
                    Button(action: {
                        Task {
                            do {
                                if isSignUp {
                                    try await authManager.signUpWithEmail(email: email, password: password)
                                } else {
                                    try await authManager.signInWithEmail(email: email, password: password)
                                }
                            } catch {
                                showError = true
                            }
                        }
                    }) {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // Google Sign In Button
                    Button(action: {
                        Task {
                            do {
                                try await authManager.signInWithGoogle()
                            } catch {
                                showError = true
                            }
                        }
                    }) {
                        HStack {
                            Image("google_logo") // Add this image to your assets
                            Text("Sign in with Google")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                    }
                    
                    // Apple Sign In Button
                    SignInWithAppleButton { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            do {
                                try await authManager.signInWithApple()
                            } catch {
                                showError = true
                            }
                        }
                    }
                    .frame(height: 44)
                    .cornerRadius(10)
                    
                    // Toggle between Sign In/Up
                    Button(action: { isSignUp.toggle() }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(authManager.errorMessage ?? "An error occurred")
            }
        }
    }
} 