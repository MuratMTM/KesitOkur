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
import FirebaseMessaging
import Reachability

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

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure App Check
        let providerFactory = AppCheckProviderFactoryImpl()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        // Configure Firebase Analytics
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Configure Firestore
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
        
        // Configure Google Sign-In
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("Error: Firebase Client ID not found")
            return true
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Optional: Check for previous sign-in more safely
        if let currentUser = GIDSignIn.sharedInstance.currentUser {
            print("Previous Google Sign-In user found: \(currentUser.userID ?? "Unknown")")
        }
        
        // Configure Firebase Messaging
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
        
        application.registerForRemoteNotifications()
        
        // Network Reachability
        setupNetworkReachability()
        
        return true
    }
    
    private func setupNetworkReachability() {
        let reachability = try? Reachability()
        
        reachability?.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
        }
        
        reachability?.whenUnreachable = { _ in
            print("Network unreachable")
            // Optionally show a network error to the user
        }
        
        do {
            try reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        print("Device Token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle received remote notification
        if let messageID = userInfo["gcm.message_id"] as? String {
            print("Received message ID: \(messageID)")
        }
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
    }
    
    // UNUserNotificationCenterDelegate method
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // MessagingDelegate method
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("Firebase registration token: \(fcmToken)")
        
        // Here you can send the token to your server
        // For example:
        // sendTokenToServer(fcmToken)
    }
    
    // Optional: Method to handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        if let messageID = userInfo["gcm.message_id"] as? String {
            print("Notification tapped for message ID: \(messageID)")
        }
        
        completionHandler()
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
    
    // Environment objects for authentication and favorites
    @StateObject private var authManager = AuthManager()
    @StateObject private var favoritesManager = FavoritesManager()
    
    var body: some Scene {
        WindowGroup {
            // Conditional view based on authentication state
            if authManager.isAuthenticated {
                MainScreenView()
                    .environmentObject(authManager)
                    .environmentObject(favoritesManager)
            } else {
                LoginPageView()
                    .environmentObject(authManager)
                    .environmentObject(favoritesManager)
            }
        }
    }
}
