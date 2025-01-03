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
                bottomButton(text:SignInLogo().googleText ,logo: SignInLogo().withGoogle )
                bottomButton(text:SignInLogo().emailText,logo: SignInLogo().withEmail)
                bottomButton(text:SignInLogo().appleText,logo: SignInLogo().withApple)
                
                
            }.padding(30)
        }
    }
}

#Preview {
    OnboardingView()
        .background(Color.yellow)
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
                .padding(.horizontal, 8)
        }
        .frame(height: 55)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(30)
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
