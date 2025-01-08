import SwiftUI
import UIKit

struct LoginPageView: View {
    @State var username: String = ""
    @State var password: String = ""
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        
        GeometryReader { geometry in
            ZStack{
                // Arka planı ZStack içinde tutuyoruz
                Image(KesitOkurAppLoginPageTexts().booksImageText)
                    .resizable()
                    .scaledToFill() // Görüntünün boyutunun ekrana tam uyum sağlamasını sağlar
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                
                VStack {
                    Spacer().frame(height: geometry.size.height * 0.1) // Yüksekliği oranla ayarlıyoruz
                    ProfileImageView(imageName: KesitOkurAppLoginPageTexts().profilePhotoImageText)
                        .frame(width: 100, height: 100) // Küçük bir profil resmi
                    AppNameTextView(appName: KesitOkurAppLoginPageTexts().appNameText)
                    
                    // Username TextField
                    TextField(KesitOkurAppLoginPageTexts().usernameBoxText, text: $username)
                        .padding(15) // Padding artırıldı
                        .background(Color.white.cornerRadius(10))
                        .frame(width: geometry.size.width * 0.8) // Ekranın genişliğine göre ayarlandı
                        .padding(.bottom, 10) // Altına daha az boşluk eklendi
                    
                    // Password SecureField
                    SecureField(KesitOkurAppLoginPageTexts().passwordBoxText, text: $password)
                        .padding(15) // Padding artırıldı
                        .background(Color.white.cornerRadius(10))
                        .frame(width: geometry.size.width * 0.8) // Ekranın genişliğine göre ayarlandı
                        .padding(.bottom, 10) // Altına daha fazla boşluk eklendi
                    
                    Spacer().frame(height: geometry.size.height * 0.01) // Alt kısımdan boşluk azaltıldı

                    Text(KesitOkurAppLoginPageTexts().forgotPasswordText)
                        .font(.system(size: 12.0, weight:.light))
                         // Altındaki boşluk azaltıldı
                    
                    Button(action: {
                        
                    }){
                        SignInButtonView(buttonName: KesitOkurAppLoginPageTexts().signInButtonText)
                    }.padding()
                    .frame(width: geometry.size.width * 0.8) // Ekranın genişliğine göre ayarlandı
                    
                    Spacer()

                    // Bottom buttons for Google, Email, Apple
                    OnboardingView().bottomButton(text:SignInLogo().googleText, logo: SignInLogo().withGoogle )
                    OnboardingView().bottomButton(text:SignInLogo().emailText, logo: SignInLogo().withEmail)
                    OnboardingView().bottomButton(text:SignInLogo().appleText, logo: SignInLogo().withApple)
                }
                .padding(.all, 10)
            }
        }
        .edgesIgnoringSafeArea(.all) // Ekranın kenarlarına kadar uzanmasını sağlarız
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
