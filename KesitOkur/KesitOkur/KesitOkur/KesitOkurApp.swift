//
//  KesitOkurApp.swift
//  KesitOkur
//
//  Created by Murat Işık on 17.03.2024.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging
import FirebaseCrashlytics
import FirebasePerformance
import FirebaseRemoteConfig
import FirebaseDynamicLinks
import FirebaseAppCheck
import FirebaseAnalytics
import FirebaseInAppMessaging




@main
struct KesitOkurApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var favoritesManager = FavoritesManager()
    
    init() {
        // Verify Firebase configuration
        guard AppConfig.firebaseApiKey != nil else {
            fatalError("Firebase API Key not found. Ensure .env file is properly configured.")
        }
        
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
