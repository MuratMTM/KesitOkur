import SwiftUI
import FirebaseAuth
import GoogleSignIn

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Main app content
                HomeView()
                    .environmentObject(authManager)
            } else {
                // Login view
                LoginView()
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

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to KesitOkur")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button(action: {
                authManager.signInWithGoogle()
            }) {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .foregroundColor(.blue)
                    Text("Sign in with Google")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct HomeView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome \(authManager.user?.displayName ?? "User")!")
                    .font(.title)
                    .padding()
                
                Button(action: {
                    try? authManager.signOut()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("KesitOkur")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
