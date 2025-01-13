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
    @StateObject private var authManager = AuthManager()
    @StateObject private var favoritesManager = FavoritesManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainScreenView()
                    .environmentObject(favoritesManager)
                    .environmentObject(authManager)
            } else {
                LoginPageView()
                    .environmentObject(authManager)
            }
        }
    }
}
