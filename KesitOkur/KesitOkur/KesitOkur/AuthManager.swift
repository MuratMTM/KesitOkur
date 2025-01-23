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
import CryptoKit

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
                self?.updateAuthenticationState(user: user)
            }
        }
    }
    
    private func updateAuthenticationState(user: User?) {
        self.user = user
        self.isAuthenticated = user != nil
        
        if let userId = user?.uid {
            Task {
                await checkAdminStatus(userId: userId)
            }
        } else {
            self.isAdmin = false
        }
        
        print("Authentication State Updated:")
        print("User: \(user?.uid ?? "None")")
        print("Authenticated: \(isAuthenticated)")
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
            print("Admin Status Check Error: \(error.localizedDescription)")
        }
    }
    
    // Email/Password Sign In
    func signInWithEmail(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
            print("Email Sign-In Successful: \(result.user.uid)")
        } catch {
            self.errorMessage = error.localizedDescription
            print("Email Sign-In Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signInWithGoogle() {
        Task { @MainActor in
            do {
                try await performGoogleSignIn()
            } catch {
                self.errorMessage = error.localizedDescription
                print("Google Sign-In Task Error: \(error.localizedDescription)")
            }
        }
    }

    private func performGoogleSignIn() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let error = NSError(domain: "GoogleSignIn", 
                                code: -1, 
                                userInfo: [NSLocalizedDescriptionKey: "Firebase Client ID not found. Check your GoogleService-Info.plist"])
            print("Google Sign-In Error: \(error.localizedDescription)")
            throw error
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
                GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
                    if let error = error {
                        print("Google Sign-In Error Details: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let signInResult = result else {
                        let noResultError = NSError(domain: "GoogleSignIn", 
                                                    code: -2, 
                                                    userInfo: [NSLocalizedDescriptionKey: "No sign-in result received"])
                        continuation.resume(throwing: noResultError)
                        return
                    }
                    
                    continuation.resume(returning: signInResult)
                }
            }
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "GoogleSignIn", 
                              code: -3, 
                              userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve Google user or ID token"])
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: result.user.accessToken.tokenString)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Save user to Firestore
            try await saveGoogleUserToFirestore(user: authResult.user, googleUser: result.user)
            
            print("Successfully signed in with Google: \(authResult.user.uid)")
            
        } catch {
            print("Google Sign-In Error: \(error.localizedDescription)")
            throw error
        }
    }

    private func saveGoogleUserToFirestore(user: User, googleUser: GIDGoogleUser) async throws {
        let db = Firestore.firestore()
        
        // Prepare user data
        var userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? googleUser.profile?.email ?? "",
            "displayName": user.displayName ?? googleUser.profile?.name ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "isAdmin": false
        ]
        
        // Add profile picture URL if available
        if let photoURL = googleUser.profile?.imageURL(withDimension: 200)?.absoluteString {
            userData["photoURL"] = photoURL
        }
        
        // Save to Firestore
        do {
            try await db.collection("users").document(user.uid).setData(userData, merge: true)
        } catch {
            print("Error saving Google user to Firestore: \(error.localizedDescription)")
            throw error
        }
    }

    // Helper method to get root view controller
    private func getRootViewController() -> UIViewController {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = scene.windows.first?.rootViewController else {
            return UIViewController()
        }
        
        return rootViewController
    }
    
    //Sign-In with Apple
    func signInWithApple() async throws {
        let nonce = randomNonceString()
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleSignInDelegate()
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate
        
        do {
            let authorization = try await withCheckedThrowingContinuation { continuation in
                delegate.continuation = continuation
                authorizationController.performRequests()
            }
            
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = appleIDCredential.identityToken,
                  let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve Apple ID credentials"])
            }
            
            let credential = OAuthProvider.credential(
                providerID: .apple, 
                idToken: identityTokenString, 
                rawNonce: nonce
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Save user to Firestore
            try await saveAppleUserToFirestore(
                user: authResult.user, 
                fullName: appleIDCredential.fullName, 
                email: appleIDCredential.email
            )
            
            print("Successfully signed in with Apple: \(authResult.user.uid)")
            
        } catch {
            print("Apple Sign-In Error: \(error.localizedDescription)")
            throw error
        }
    }

    private func saveAppleUserToFirestore(user: User, fullName: PersonNameComponents?, email: String?) async throws {
        let db = Firestore.firestore()
        
        // Prepare user data
        var userData: [String: Any] = [
            "uid": user.uid,
            "email": user.email ?? email ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "isAdmin": false
        ]
        
        // Add full name if available
        if let fullName = fullName {
            userData["displayName"] = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
        }
        
        // Save to Firestore
        do {
            try await db.collection("users").document(user.uid).setData(userData, merge: true)
        } catch {
            print("Error saving Apple user to Firestore: \(error.localizedDescription)")
            throw error
        }
    }
    
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
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
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

class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var continuation: CheckedContinuation<ASAuthorization, Error>?

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window found")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
    }
}

enum AuthError: Error {
    case missingToken
    case invalidToken
}
