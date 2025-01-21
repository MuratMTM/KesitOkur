import SwiftUI
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices

struct LoginPageView: View {
    @StateObject private var authManager = AuthManager()
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingSignUp = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                ZStack {
                    // Background
                    Image(KesitOkurAppLoginPageTexts().booksImageText)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                        .ignoresSafeArea()
                    
                    // Content
                    VStack(spacing: geometry.size.height * 0.02) {
                        Spacer(minLength: geometry.size.height * 0.05)
                        
                        // Profile Image and App Name
                        ProfileImageView(imageName: KesitOkurAppLoginPageTexts().profilePhotoImageText)
                            .frame(width: min(geometry.size.width * 0.3, 120),
                                   height: min(geometry.size.width * 0.3, 120))
                        
                        AppNameTextView(appName: KesitOkurAppLoginPageTexts().appNameText)
                            .padding(.bottom, geometry.size.height * 0.01)
                        
                        // Login Fields
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
                        
                        // Forgot Password
                        Text(KesitOkurAppLoginPageTexts().forgotPasswordText)
                            .font(.system(size: min(12, geometry.size.width * 0.03), weight: .light))
                            .padding(.top, 5)
                        
                        // Sign In Button
                        LoginButton(width: min(geometry.size.width * 0.85, 400),
                                  height: min(50, geometry.size.height * 0.06),
                                  title: KesitOkurAppLoginPageTexts().signInButtonText) {
                            Task {
                                do {
                                    try await authManager.signInWithEmail(email: email, password: password)
                                } catch {
                                    showError = true
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                        
                        // Divider
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
                        
                        // Social Login Buttons
                        VStack(spacing: min(12, geometry.size.height * 0.015)) {
                            // Sign Up Button
                            LoginButton(width: min(geometry.size.width * 0.85, 400),
                                      height: min(50, geometry.size.height * 0.06),
                                      backgroundColor: .black,
                                      foregroundColor: .white,
                                      title: "Kayıt Ol") {
                                showingSignUp = true
                            }
                            
                            // Google Sign In
                            Button(action: {
                                Task {
                                    do {
                                        try await authManager.signInWithGoogle()
                                    } catch {
                                        showError = true
                                        errorMessage = error.localizedDescription
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
                            
                            // Apple Sign In
                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [.fullName, .email]
                                },
                                onCompletion: { result in
                                    Task {
                                        do {
                                            try await authManager.signInWithApple()
                                        } catch {
                                            showError = true
                                            errorMessage = error.localizedDescription
                                        }
                                    }
                                }
                            )
                            .frame(width: min(geometry.size.width * 0.85, 400),
                                   height: min(50, geometry.size.height * 0.06))
                            .cornerRadius(10)
                        }
                        
                        Spacer(minLength: geometry.size.height * 0.05)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
                .environmentObject(authManager)
        }
    }
}

// Custom Button Style
struct LoginButton: View {
    let width: CGFloat
    let height: CGFloat
    var backgroundColor: Color = Color.yellow.opacity(0.8)
    var foregroundColor: Color = .black
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(width: width, height: height)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(10)
                .font(.system(size: min(16, width * 0.04), weight: .semibold))
        }
    }
}

// Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 3)
            .tint(.black) // Sets the cursor and selection color
            .accentColor(.black) // Sets the focus color
    }
}

struct ProfileImageView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .clipShape(Circle())
            .overlay {
                Circle().stroke(.yellow, lineWidth: 5)
            }
            .shadow(radius: 10)
    }
}

struct AppNameTextView: View {
    let appName: String
    
    var body: some View {
        Text(appName)
            .font(.system(size: 16, weight: .bold))
            .italic()
            .padding(.bottom, 10)
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
    }
}
