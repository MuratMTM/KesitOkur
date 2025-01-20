//
//  AuthManager.swift
//  KesitOkur
//
//  Created by Murat Işık on 13.01.2025.
//



import Foundation
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import FirebaseCore
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
    
    deinit {
        // Remove the listener when the AuthManager is deallocated
        if let handle = stateListener {
            Auth.auth().removeStateDidChangeListener(handle)
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
        
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = await windowScene.windows.first,
              let rootViewController = await window.rootViewController else {
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
        
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.performRequests()
            
            class Delegate: NSObject, ASAuthorizationControllerDelegate {
                let continuation: CheckedContinuation<ASAuthorization, Error>
                
                init(continuation: CheckedContinuation<ASAuthorization, Error>) {
                    self.continuation = continuation
                }
                
                func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
                    continuation.resume(returning: authorization)
                }
                
                func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
                    continuation.resume(throwing: error)
                }
            }
            
            let delegate = Delegate(continuation: continuation)
            controller.delegate = delegate
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }
        
        if let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw AuthError.invalidToken
            }
            
            let nonce = randomNonceString()
            let credential = OAuthProvider.credential(
                providerID: AuthProviderID.apple,
                idToken: idTokenString,
                rawNonce: nonce,
                accessToken: nil
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            DispatchQueue.main.async {
                self.user = authResult.user
                self.isAuthenticated = true
            }
        }
    }
    
    // Helper function to generate nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
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
    
    // Add this function to your existing AuthManager class
    func signUp(email: String, password: String, firstName: String, lastName: String, birthDate: Date) async throws {
        do {
            // Create the user in Firebase Auth
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create user profile in Firestore
            let db = Firestore.firestore()
            try await db.collection("users").document(result.user.uid).setData([
                "firstName": firstName,
                "lastName": lastName,
                "email": email,
                "birthDate": birthDate,
                "createdAt": Date(),
                "isAdmin" : false
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
