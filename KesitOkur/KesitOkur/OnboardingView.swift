//
//  OnboardingView.swift
//  KesitOkur
//
//  Created by Murat Işık on 20.03.2024.
//

import SwiftUI

struct OnboardingView: View {
    @State var onboardingState: Int = 0
    
    var body: some View {
        ZStack{
            //content
            
            //buttons
            VStack{
                Spacer()
                bottomButton( logo: SignInLogo().withGoogle,text:SignInLogo().googleText )
                bottomButton(logo: SignInLogo().withEmail,text:SignInLogo().emailText)
                bottomButton(logo: SignInLogo().withApple,text:SignInLogo().appleText)
                
                
            }.padding(30)
        }
    }
}

#Preview {
    OnboardingView()
        .background(Color.yellow)
}



extension OnboardingView {
     func bottomButton(logo: Image, text: String) -> some View {
        HStack {
            Text("Sign in with")
                .font(.headline)
                .foregroundStyle(.gray)
            
            Text(text)
                .font(.headline)
                .foregroundColor(.gray)
                
            
            logo
                .resizable()
                .frame(width: 30, height: 25)
                .padding(.horizontal, 8)
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(30)
        .onTapGesture {
            // Butona tıklama işlemi burada gerçekleşir
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
