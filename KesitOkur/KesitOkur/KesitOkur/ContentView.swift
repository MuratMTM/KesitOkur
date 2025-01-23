import SwiftUI
import FirebaseAuth
import GoogleSignIn

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainScreenView()
                    .environmentObject(authManager)
            } else {
                LoginPageView()
                    .environmentObject(authManager)
            }
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
        .onChange(of: authManager.isAuthenticated) { newValue in
            print("Authentication state changed: \(newValue)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
