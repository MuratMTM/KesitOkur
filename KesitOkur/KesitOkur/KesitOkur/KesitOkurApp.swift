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

// Use a factory method instead of a class
class AppCheckProviderFactoryImpl: NSObject, AppCheckProviderFactory{
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
#if DEBUG
        return AppCheckDebugProvider(app: app)
#else
        return DeviceCheckProvider(app: app)
#endif
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure App Check
        let providerFactory = AppCheckProviderFactoryImpl()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Configure Google Sign-In
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                print("Error restoring Google Sign-In: \(error.localizedDescription)")
            }
        }
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle Google Sign-In and other URL schemes
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct KesitOkurApp: App {
    // Use UIApplicationDelegateAdaptor to integrate AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Optional: Environment object for authentication state
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            // Conditional view based on authentication state
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}


// Optional: Main Tab View after Authentication
struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
            
            // Add more tabs as needed
        }
    }
}

// Placeholder views - replace with your actual implementations
struct HomeView: View {
    var body: some View {
        Text("Home View")
    }
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack {
            Button("Sign In with Google") {
                Task {
                    await authManager.signInWithGoogle()
                }
            }
            
            Button("Sign In with Apple") {
                Task {
                    try? await authManager.signInWithApple()
                }
            }
        }
    }
}

