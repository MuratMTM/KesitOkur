import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

struct LoginPageView: View {
    // MARK: - State Properties
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingSignUp = false
    @State private var isLoading: Bool = false
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView(geometry: geometry)
                
                // Content
                ScrollView(showsIndicators: false) {
                    loginContentView(geometry: geometry)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .errorAlert(isPresented: $showError, message: errorMessage)
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
                .environmentObject(authManager)
        }
    }
    
    // MARK: - Background View
    private func backgroundView(geometry: GeometryProxy) -> some View {
        Image(KesitOkurAppLoginPageTexts().booksImageText)
            .resizable()
            .scaledToFill()
            .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
            .ignoresSafeArea()
    }
    
    // MARK: - Login Content View
    private func loginContentView(geometry: GeometryProxy) -> some View {
        VStack(spacing: geometry.size.height * 0.02) {
            Spacer(minLength: geometry.size.height * 0.05)
            
            // Profile Image and App Name
            ProfileImageView(imageName: KesitOkurAppLoginPageTexts().profilePhotoImageText)
                .frame(width: min(geometry.size.width * 0.3, 120),
                       height: min(geometry.size.width * 0.3, 120))
            
            AppNameTextView(appName: KesitOkurAppLoginPageTexts().appNameText)
                .padding(.bottom, geometry.size.height * 0.01)
            
            // Login Fields
            loginFieldsView(geometry: geometry)
            
            // Sign In Button
            signInButton(geometry: geometry)
            
            // Divider
            dividerView(geometry: geometry)
            
            // Social Login Buttons
            socialLoginButtons(geometry: geometry)
            
            Spacer(minLength: geometry.size.height * 0.05)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Login Fields View
    private func loginFieldsView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Email Field
            TextField(KesitOkurAppLoginPageTexts().usernameBoxText, text: $email)
                .textFieldStyle(CustomTextFieldStyle())
                .frame(maxWidth: min(geometry.size.width * 0.85, 400))
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .foregroundColor(.black)
            
            // Password Field
            SecureField(KesitOkurAppLoginPageTexts().passwordBoxText, text: $password)
                .textFieldStyle(CustomTextFieldStyle())
                .frame(maxWidth: min(geometry.size.width * 0.85, 400))
                .foregroundColor(.black)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Sign In Button
    private func signInButton(geometry: GeometryProxy) -> some View {
        LoginButton(
            width: min(geometry.size.width * 0.85, 400),
            height: min(50, geometry.size.height * 0.06),
            title: KesitOkurAppLoginPageTexts().signInButtonText,
            isLoading: isLoading
        ) {
            performEmailSignIn()
        }
    }
    
    // MARK: - Divider View
    private func dividerView(geometry: GeometryProxy) -> some View {
        HStack {
            Rectangle()
                .frame(height: 1)
            Text("veya")
                .foregroundColor(.black.opacity(0.6))
                .font(.system(size: min(14, geometry.size.width * 0.035)))
            Rectangle()
                .frame(height: 1)
        }
        .foregroundColor(.black.opacity(0.3))
        .frame(width: min(geometry.size.width * 0.85, 400))
        .padding(.vertical, geometry.size.height * 0.01)
    }
    
    // MARK: - Social Login Buttons
    private func socialLoginButtons(geometry: GeometryProxy) -> some View {
        VStack(spacing: min(12, geometry.size.height * 0.015)) {
            // Sign Up Button
            LoginButton(
                width: min(geometry.size.width * 0.85, 400),
                height: min(50, geometry.size.height * 0.06),
                backgroundColor: .black,
                foregroundColor: .white,
                title: "Kayıt Ol"
            ) {
                showingSignUp = true
            }
            
            // Google Sign In
            googleSignInButton(geometry: geometry)
            
            // Apple Sign In
            appleSignInButton(geometry: geometry)
        }
    }
    
    // MARK: - Google Sign In Button
    private func googleSignInButton(geometry: GeometryProxy) -> some View {
        Button(action: {
            Task { @MainActor in
                do {
                    try await performGoogleSignIn()
                } catch {
                    showErrorMessage(error.localizedDescription)
                }
            }
        }) {
            HStack {
                Image("googleLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: min(20, geometry.size.width * 0.05),
                           height: min(20, geometry.size.width * 0.05))
                Text("Google ile Devam Et")
                    .font(.system(size: min(16, geometry.size.width * 0.04), weight: .semibold))
            }
            .frame(width: min(geometry.size.width * 0.85, 400),
                   height: min(50, geometry.size.height * 0.06))
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 3)
        }
    }
    
    // MARK: - Perform Google Sign In
    @MainActor
    private func performGoogleSignIn() async throws {
        isLoading = true
        defer { isLoading = false }
        
        Task{
           
                 authManager.signInWithGoogle()
                // No need to explicitly set isAuthenticated, AuthManager handles this
            
        }
    }
    
    // MARK: - Apple Sign In Button
    private func appleSignInButton(geometry: GeometryProxy) -> some View {
        SignInWithAppleButton(
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: { result in
                switch result {
                case .success(_):
                    Task { @MainActor in
                        do {
                            try await authManager.signInWithApple()
                        } catch {
                            showErrorMessage(error.localizedDescription)
                        }
                    }
                case .failure(let error):
                    showErrorMessage(error.localizedDescription)
                }
            }
        )
        .frame(width: min(geometry.size.width * 0.85, 400),
               height: min(geometry.size.height * 0.06, 50),
               alignment: .center)
        .cornerRadius(10)
    }
    
    // MARK: - Perform Apple Sign In
    @MainActor
    private func performAppleSignIn() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authManager.signInWithApple()
            // No need to explicitly set isAuthenticated, AuthManager handles this
        } catch {
            showErrorMessage(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Authentication Methods
    private func performEmailSignIn() {
        guard !email.isEmpty, !password.isEmpty else {
            showErrorMessage("Email ve şifre boş bırakılamaz")
            return
        }
        
        isLoading = true
        Task { @MainActor in
            do {
                try await authManager.signInWithEmail(email: email, password: password)
                isLoading = false
            } catch {
                showErrorMessage(error.localizedDescription)
                isLoading = false
            }
        }
    }
    
    // MARK: - Error Handling
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Error Alert View Modifier
extension View {
    func errorAlert(isPresented: Binding<Bool>, message: String) -> some View {
        self.alert("Hata", isPresented: isPresented) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(message)
        }
    }
}

// MARK: - Login Button
struct LoginButton: View {
    let width: CGFloat
    let height: CGFloat
    var backgroundColor: Color = Color.yellow.opacity(0.8)
    var foregroundColor: Color = .black
    let title: String
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                } else {
                    Text(title)
                }
            }
            .frame(width: width, height: height)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(10)
            .font(.system(size: min(16, width * 0.04), weight: .semibold))
        }
        .disabled(isLoading)
    }
}

// MARK: - Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 3)
            .tint(.black)
            .accentColor(.black)
    }
}

// Placeholder for other view components
struct ProfileImageView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .clipShape(Circle())
    }
}

struct AppNameTextView: View {
    let appName: String
    
    var body: some View {
        Text(appName)
            .font(.title)
            .fontWeight(.bold)
    }
}

struct OnboardingView: View {
    @State var onboardingState: Int = 0
    
    var body: some View {
        ZStack{
            //content
            
            //buttons
            VStack(spacing: 15){
               
                bottomButton(text:SignInLogo().googleText ,logo: SignInLogo().withGoogle )
                   
                bottomButton(text:SignInLogo().emailText,logo: SignInLogo().withEmail)
            
                bottomButton(text:SignInLogo().appleText,logo: SignInLogo().withApple)
                
                
            }.padding(.vertical, 30)
        }
    }
}


extension OnboardingView {
     func bottomButton( text: String,logo: Image) -> some View {
        HStack {
           
            
            Text(text)
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("ile Giriş Yap")
                .font(.headline)
                .foregroundStyle(.gray)
                
            
            logo
                .resizable()
                .frame(width: 30, height: 25)
                .padding(.horizontal, 10)
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(20)
        .onTapGesture {
            
        }
     }
}


struct SignInLogo {
    var googleText: String = "Google"
    var emailText: String = "Email"
    var appleText: String = "Apple"
    
    var withGoogle: Image = Image("googleLogo")
    var withEmail: Image = Image("emailLogo")
     var withApple: Image = Image("appleLogo")
    
}

struct LoginPageView_Previews: PreviewProvider {
    static var previews: some View {
        LoginPageView()
            .environmentObject(AuthManager())
    }
}
