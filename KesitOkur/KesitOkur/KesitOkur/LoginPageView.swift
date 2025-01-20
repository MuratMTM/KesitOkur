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
            ZStack {
                // Background
                Spacer()
                Image(KesitOkurAppLoginPageTexts().booksImageText)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .padding(.top)
                
                VStack(spacing: 25) {
                    // Profile Image and App Name
                    ProfileImageView(imageName: KesitOkurAppLoginPageTexts().profilePhotoImageText)
                        .frame(width: 150, height: 150)
                    AppNameTextView(appName: KesitOkurAppLoginPageTexts().appNameText)
                        .padding(.bottom, 20)
                    
                    // Login Fields
                    VStack(spacing: 15) {
                        // Email Field
                        TextField(KesitOkurAppLoginPageTexts().usernameBoxText, text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .frame(width: geometry.size.width * 0.8)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        // Password Field
                        SecureField(KesitOkurAppLoginPageTexts().passwordBoxText, text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .frame(width: geometry.size.width * 0.8)
                    }
                    
                    // Forgot Password
                    Text(KesitOkurAppLoginPageTexts().forgotPasswordText)
                        .font(.system(size: 12.0, weight: .light))
                        .padding(.top, 5)
                    
                    // Sign In Button
                    Button(action: {
                        Task {
                            do {
                                try await authManager.signInWithEmail(email: email, password: password)
                            } catch {
                                showError = true
                                errorMessage = error.localizedDescription
                            }
                        }
                    }) {
                        Text(KesitOkurAppLoginPageTexts().signInButtonText)
                            .frame(width: geometry.size.width * 0.8, height: 50)
                            .background(Color.yellow.opacity(0.8))
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .font(.headline)
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                        Text("veya")
                            .foregroundColor(.black.opacity(0.6))
                        Rectangle()
                            .frame(height: 1)
                    }
                    .foregroundColor(.black.opacity(0.3))
                    .frame(width: geometry.size.width * 0.8)
                  
                    
                    // Social Login Buttons
                    VStack(spacing: 15) {
                        
                        Button(action: {
                            showingSignUp = true
                        }) {
                            Text("Kayıt Ol")
                                .frame(width: geometry.size.width * 0.8, height: 50)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .font(.headline)
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
                                    .frame(width: 20, height: 20)
                                Text("Google ile Devam Et")
                                    .font(.headline)
                                
                            }
                            .frame(width: geometry.size.width * 0.8, height: 50)
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
                        .frame(width: geometry.size.width * 0.8, height: 50)
                        .cornerRadius(10)
                    }
                    
                   
                }
                .padding(.horizontal)
            }
        }.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
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

// Custom TextField Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(15)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.1), radius: 3)
    }
}

struct ProfileImageView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit() // Görselin boyutunun alanla uyumlu olmasını sağlar
            .clipShape(Circle())
            .overlay {
                Circle().stroke(.yellow, lineWidth: 5)
            }
            .shadow(radius: 20)
    }
}

struct AppNameTextView: View {
    let appName: String
    
    var body: some View {
        Text(appName)
            .font(.system(size: 16.0, weight: .bold))
            .italic()
            .font(.largeTitle)
            .padding(.bottom, 20)
    }
}

struct SignInButtonView: View {
    let buttonName: String
    
    var body: some View {
        Text(buttonName)
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow.opacity(50))
            .cornerRadius(20)
    }
}

#Preview {
    LoginPageView()
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
