//
//  KesitOkurApp.swift
//  KesitOkur
//
//  Created by Murat Işık on 17.03.2024.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FirebaseAppCheck
import FirebaseFirestore
import FirebaseStorage
import FirebaseCrashlytics
import FirebasePerformance
import FirebaseRemoteConfig
import FirebaseDynamicLinks
import FirebaseAnalytics
import FirebaseInAppMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure App Check for Production
                #if DEBUG
                let providerFactory = AppCheckDebugProviderFactory()
                #else
                let providerFactory = DeviceCheckProviderFactory()
                #endif
                AppCheck.setAppCheckProviderFactory(providerFactory)
        
        return true
    }
    
    func application(_ app: UIApplication,
                    open url: URL,
                    options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct KesitOkurApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var favoritesManager = FavoritesManager()
    
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    init() {
        // Verify Firebase configuration
        guard AppConfig.firebaseApiKey != nil else {
            fatalError("Firebase API Key not found. Ensure .env file is properly configured.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favoritesManager)
                .environmentObject(authManager)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
