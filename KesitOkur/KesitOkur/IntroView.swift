//
//  ContentView.swift
//  KesitOkur
//
//  Created by Murat Işık on 17.03.2024.
//

import SwiftUI
import UIKit

struct IntroView: View {
    @State var username: String = ""
    @State var password: String = ""
    
   
    
    var body: some View {
        
            ZStack{
                Image("books")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack{
                    Spacer()
                    Image("profilePhoto")
                        .resizable()
                        .frame(width: 200,height: 200, alignment: .center)
                        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                        .overlay{
                            Circle().stroke(.yellow,lineWidth: 5)
                        }
                        .shadow(radius: /*@START_MENU_TOKEN@*/20/*@END_MENU_TOKEN@*/)
                    
                    Text("KesitOkur")
                        .fontWeight(.bold)
                        .italic()
                        .font(.largeTitle)
                        .padding(.bottom,80)
                        
                    
                        
                        
                    TextField("username", text: $username)
                        .padding(20)
                        .background(Color.white.cornerRadius(10))
                    
                    SecureField("password", text: $password)
                        .padding(20)
                        .background(Color.white.cornerRadius(10))
                    Spacer()
                    
                  
                    
                        Button(action: {
                            
                                       
                            }){
                                           Text("Sign In")
                                    .frame(maxWidth: 200)
                                               .padding()
                                               .foregroundColor(.white)
                                               .background(Color.yellow.opacity(50))
                                               .cornerRadius(20)
                                               
                        }.padding()
                   
                    Spacer()
                    OnboardingView().bottomButton( logo: SignInLogo().withGoogle,text:SignInLogo().googleText )
                    OnboardingView().bottomButton(logo: SignInLogo().withEmail,text:SignInLogo().emailText)
                    OnboardingView().bottomButton(logo: SignInLogo().withApple,text:SignInLogo().appleText)
                }.padding(.all, 10)
                
            }
        
        
    }
   
}

#Preview {
    IntroView()
}
