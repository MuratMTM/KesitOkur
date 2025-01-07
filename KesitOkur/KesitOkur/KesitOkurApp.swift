//
//  KesitOkurApp.swift
//  KesitOkur
//
//  Created by Murat Işık on 17.03.2024.
//

import SwiftUI
import FirebaseCore



class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                     [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct KesitOkurApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            NavigationView{
                WelcomeView()
            }
        }
    }
}
