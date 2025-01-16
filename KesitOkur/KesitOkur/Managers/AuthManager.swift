import Foundation
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isAdmin = false
    
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
            self?.isAuthenticated = user != nil
            
            // Check admin status when user changes
            if let userId = user?.uid {
                self?.checkAdminStatus(userId: userId)
            } else {
                self?.isAdmin = false
            }
        }
    }
    
    // Add this method to check admin status
    private func checkAdminStatus(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let data = snapshot?.data(),
               let isAdmin = data["isAdmin"] as? Bool {
                DispatchQueue.main.async {
                    self?.isAdmin = isAdmin
                }
            }
        }
    }
    
    // Email/Password Sign In
    func signInWithEmail(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // Google Sign In
    func signInWithGoogle() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else { throw AuthError.missingToken }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            DispatchQueue.main.async {
                self.user = authResult.user
                self.isAuthenticated = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // Sign in with Apple
    func signInWithApple() async throws {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let result = try await withCheckedThrowingContinuation { continuation in
            ASAuthorizationController(authorizationRequests: [request])
                .performRequests()
        }
        
        if let appleIDCredential = result as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken else {
                throw AuthError.missingToken
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthError.invalidToken
            }
            
            let credential = OAuthProvider.credential(
                withProviderID: "apple.com",
                idToken: idTokenString,
                rawNonce: nil
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            DispatchQueue.main.async {
                self.user = authResult.user
                self.isAuthenticated = true
            }
        }
    }
    
    // Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.isAuthenticated = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // Sign Up
    func signUp(email: String, password: String, firstName: String, lastName: String, birthDate: Date) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(result.user.uid).setData([
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "birthDate": birthDate,
                "createdAt": Date(),
                "isAdmin": false
            ])
            
            DispatchQueue.main.async {
                self.user = result.user
                self.isAuthenticated = true
                self.isAdmin = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
}

enum AuthError: Error {
    case missingToken
    case invalidToken
} 