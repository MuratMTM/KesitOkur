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
                bottomButton
                
                
            }.padding(30)
        }
    }
}

#Preview {
    OnboardingView()
        .background(Color.yellow)
}



extension OnboardingView {
    private var bottomButton: some View {
        Text("Sign In")
            .font(.headline)
            .foregroundColor(.yellow)
            .frame(height: 55)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(30)
            .onTapGesture {
                
            }
    }

}
