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
        Task {
            do {
                guard let clientID = FirebaseApp.app()?.options.clientID else {
                    self.errorMessage = "Error getting client ID"
                    return
                }
                
                let config = GIDConfiguration(clientID: clientID)
                GIDSignIn.sharedInstance.configuration = config
                
                guard let topVC = await getTopViewController() else {
                    self.errorMessage = "Could not get top view controller"
                    return
                }
                
                let userResult: GIDSignInResult = try await withCheckedThrowingContinuation { continuation in
                    DispatchQueue.main.async {
                        GIDSignIn.sharedInstance.signIn(withPresenting: topVC) { result, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                                return
                            }
                            guard let result = result else {
                                continuation.resume(throwing: NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No sign-in result"]))
                                return
                            }
                            continuation.resume(returning: result)
                        }
                    }
                }
                
                // Add additional validation for ID token
                guard let idToken = userResult.user.idToken?.tokenString else {
                    throw NSError(domain: "GoogleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid or expired ID token"])
                }
                
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: userResult.user.accessToken.tokenString
                )
                
                // Add retry mechanism for credential sign-in
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)
                    await MainActor.run {
                        self.user = authResult.user
                        self.isAuthenticated = true
                    }
                } catch {
                    // Specific handling for credential-related errors
                    if let authError = error as NSError?,
                       authError.domain == "FIRAuthErrorDomain",
                       authError.code == AuthErrorCode.invalidCredential.rawValue {
                        // Attempt re-authentication or prompt user to sign in again
                        self.errorMessage = "Authentication failed. Please try signing in again."
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    throw error
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    print("Google Sign-In Error: \(error.localizedDescription)")
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
                providerID:.apple,
                    idToken: idTokenString,
                    rawNonce: nonce,
                    accessToken: nil
            )
            
            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                
                // Update user profile if name is provided
                if let fullName = appleIDCredential.fullName {
                    let changeRequest = authResult.user.createProfileChangeRequest()
                    changeRequest.displayName = "\(fullName.givenName ?? "") \(fullName.familyName ?? "")"
                    try await changeRequest.commitChanges()
                }
                
                self.user = authResult.user
                self.isAuthenticated = true
                
            } catch {
                // Handle specific credential errors
                if let authError = error as NSError?,
                   authError.domain == "FIRAuthErrorDomain",
                   authError.code == AuthErrorCode.invalidCredential.rawValue {
                    self.errorMessage = "Invalid or expired authentication. Please try again."
                } else {
                    self.errorMessage = error.localizedDescription
                }
                throw error
            }
        } catch {
            self.errorMessage = error.localizedDescription
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
