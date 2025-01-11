//
//  KesitOkurApp.swift
//  KesitOkur
//
//  Created by Murat Işık on 17.03.2024.
//

import SwiftUI
import FirebaseCore




@main
struct KesitOkurApp: App {
    @StateObject private var favoritesManager = FavoritesManager()
    
    init() {
           FirebaseApp.configure()
       }
    
    var body: some Scene {
        WindowGroup {
            NavigationView{
                LoginPageView()
            }
            .environmentObject(favoritesManager)
        }
    }
}
