//
//  AuthManager.swift
//  KesitOkur
//
//  Created by Murat Işık on 13.01.2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
import FirebaseFirestore
import AuthenticationServices

@MainActor
class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isAdmin = false
    
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        stateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
                self?.user = user
                
                if let userId = user?.uid {
                    await self?.checkAdminStatus(userId: userId)
                } else {
                    self?.isAdmin = false
                }
            }
        }
    }
    
    private func checkAdminStatus(userId: String) async {
        do {
            let db = Firestore.firestore()
            let document = try await db.collection("users").document(userId).getDocument()
            if let data = document.data(),
               let isAdmin = data["isAdmin"] as? Bool {
                self.isAdmin = isAdmin
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // Email/Password Sign In
    func signInWithEmail(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signInWithGoogle() {
        Task {
            do {
                guard let clientID = FirebaseApp.app()?.options.clientID else {
                    self.errorMessage = "Error getting client ID"
                    return
                }
                
                let config = GIDConfiguration(clientID: clientID)
                GIDSignIn.sharedInstance.configuration = config
                
                // Get the top view controller
                guard let topVC = await getTopViewController() else {
                    self.errorMessage = "Could not get top view controller"
                    return
                }
                
                // Use async/await for sign in with explicit type
                let userResult: GIDSignInResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
                    DispatchQueue.main.async {
                        GIDSignIn.sharedInstance.signIn(withPresenting: topVC) { result, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                                return
                            }
                            guard let result = result else {
                                continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No result returned"]))
                                return
                            }
                            continuation.resume(returning: result)
                        }
                    }
                }
                
                guard let idToken = userResult.user.idToken?.tokenString else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID token"])
                }
                
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: userResult.user.accessToken.tokenString
                )
                
                let authResult = try await Auth.auth().signIn(with: credential)
                await MainActor.run {
                    self.user = authResult.user
                    self.isAuthenticated = true
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func getTopViewController() async -> UIViewController? {
        await MainActor.run {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            
            guard let rootVC = window?.rootViewController else {
                return nil
            }
            
            var topVC = rootVC
            while let presentedVC = topVC.presentedViewController {
                topVC = presentedVC
            }
            return topVC
        }
    }
    
    // Sign in with Apple
    func signInWithApple() async throws {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let result: ASAuthorization = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
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
            await MainActor.run {
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
    
    func signOut() {
        Task { @MainActor in
            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
                self.user = nil
                self.isAuthenticated = false
                self.isAdmin = false
            } catch {
                self.errorMessage = error.localizedDescription
            }
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
            
            self.user = result.user
            self.isAuthenticated = true
            self.isAdmin = false
            
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }
}

enum AuthError: Error {
    case missingToken
    case invalidToken
}
