import SwiftUI
import FirebaseAuth
import GoogleSignIn

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Main app content
                MainScreenView()
                    .environmentObject(authManager)
            } else {
                // Login view
                LoginPageView()
                    .environmentObject(authManager)
            }
        }
        .alert("Error", isPresented: .constant(authManager.errorMessage != nil)) {
            Button("OK") {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "")
        }
        .onOpenURL { url in
            GIDSignIn.sharedInstance.handle(url)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager())
    }
}
