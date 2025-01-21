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
        Task { @MainActor in
            do {
                try await performGoogleSignIn()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func performGoogleSignIn() async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client ID not found"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<GIDSignInResult, Error>) in
            GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) { result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let signInResult = result else {
                    continuation.resume(throwing: NSError(domain: "GoogleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "No sign-in result"]))
                    return
                }
                
                continuation.resume(returning: signInResult)
            }
        }
        
        // Validate ID token
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid ID token"])
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        
        let authResult = try await Auth.auth().signIn(with: credential)
        
        await MainActor.run {
            self.user = authResult.user
            self.isAuthenticated = true
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
        
        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorization, Error>) in
                let controller = ASAuthorizationController(authorizationRequests: [request])
                let delegate = AppleSignInDelegate(continuation: continuation)
                controller.delegate = delegate
                controller.presentationContextProvider = delegate
                controller.performRequests()
                
                // Store delegate to prevent it from being deallocated
                objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            }
            
            guard let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential,
                  let appleIDToken = appleIDCredential.identityToken,
                  let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])
            }
            
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: idTokenString,
                rawNonce: nonce
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            
            // Create profile change request
            let changeRequest = firebaseUser.createProfileChangeRequest()
            
            // Update display name if full name is available
            if let fullName = appleIDCredential.fullName {
                let displayName = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                changeRequest.displayName = displayName
            }
            
            // Commit profile changes
            try await changeRequest.commitChanges()
            
            // Save user information to Firestore
            try await saveAppleUserToFirestore(
                user: firebaseUser,
                fullName: appleIDCredential.fullName,
                email: appleIDCredential.email
            )
            
            // Update local state
            self.user = firebaseUser
            self.isAuthenticated = true
            
        } catch {
            // Detailed error handling
            if let authError = error as NSError?,
               authError.domain == "FIRAuthErrorDomain",
               authError.code == AuthErrorCode.invalidCredential.rawValue {
                self.errorMessage = "Invalid or expired authentication. Please try again."
            } else {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    // Helper method to save Apple user details to Firestore
    private func saveAppleUserToFirestore(
        user: User,
        fullName: PersonNameComponents?,
        email: String?
    ) async throws {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        var userData: [String: Any] = [
            "uid": user.uid,
            "providerID": "apple.com"
        ]
        
        if let fullName = fullName {
            userData["firstName"] = fullName.givenName ?? ""
            userData["lastName"] = fullName.familyName ?? ""
        }
        
        if let email = email {
            userData["email"] = email
        }
        
        try await userRef.setData(userData, merge: true)
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
    private let continuation: CheckedContinuation<ASAuthorization, Error>
    
    init(continuation: CheckedContinuation<ASAuthorization, Error>) {
        self.continuation = continuation
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.windows.first else {
            fatalError("No window found")
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }
}

enum AuthError: Error {
    case missingToken
    case invalidToken
}
