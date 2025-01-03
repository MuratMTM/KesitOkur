

import SwiftUI
import UIKit

struct LoginPageView: View {
    @State var username: String = ""
    @State var password: String = ""
    @State private var isLoggedIn: Bool = false
    
    
    
    var body: some View {
        
        ZStack{
            Image(KesitOkurAppLoginPageTexts().booksImageText)
                .resizable()
                .ignoresSafeArea()
            
            VStack{
                Spacer()
                ProfileImageView(imageName: KesitOkurAppLoginPageTexts().profilePhotoImageText)
                AppNameTextView(appName: KesitOkurAppLoginPageTexts().appNameText)
                
                TextField(KesitOkurAppLoginPageTexts().usernameBoxText, text: $username)
                    .padding(20)
                    .background(Color.white.cornerRadius(10))
                
                SecureField(KesitOkurAppLoginPageTexts().passwordBoxText, text: $password)
                    .padding(20)
                    .background(Color.white.cornerRadius(10))
                
                Spacer()
                
                Text(KesitOkurAppLoginPageTexts().forgotPasswordText)
                    .font(.system(size: 12.0, weight:.light))
                
                
                Button(action: {
                    
                }){
                    SignInButtonView(buttonName: KesitOkurAppLoginPageTexts().signInButtonText)
                }.padding()
                
                Spacer()
                
                OnboardingView().bottomButton(text:SignInLogo().googleText, logo: SignInLogo().withGoogle )
                OnboardingView().bottomButton(text:SignInLogo().emailText,logo: SignInLogo().withEmail)
                OnboardingView().bottomButton(text:SignInLogo().appleText,logo: SignInLogo().withApple)
                
            }.padding(.all, 10)
            
        }
        
        
    }
    
}


struct ProfileImageView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .frame(width: 200, height: 200, alignment: .center)
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
            .padding(.bottom, 80)
    }
}

struct SignInButtonView: View {
    let buttonName: String
    
    var body: some View {
        Text(buttonName)
            .frame(maxWidth: 200)
            .padding()
            .foregroundColor(.white)
            .background(Color.yellow.opacity(50))
            .cornerRadius(20)
    }
}

#Preview {
    LoginPageView()
}
