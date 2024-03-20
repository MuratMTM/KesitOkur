//
//  WelcomeView.swift
//  KesitOkur
//
//  Created by Murat Işık on 20.03.2024.
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("signed_in") var currentUserSignedIn: Bool = false
    var body: some View {
        ZStack{
            RadialGradient(
                gradient: Gradient(colors: [.yellow, .white]),
                center: .bottom,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height
            )
            .ignoresSafeArea()
            
            if currentUserSignedIn{
                Text("ProfileView")
            } else{
                Text("OnBoardingView")
            }
        }
    }
}

#Preview {
    WelcomeView()
}
