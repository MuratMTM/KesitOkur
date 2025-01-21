import Foundation
import FirebaseCore
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import GoogleSignIn
import UIKit

class AdminBookViewModel: ObservableObject {
    // Authentication and User State
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    // Book and Excerpt Management
    @Published var currentBook: Book?
    @Published var selectedImages: [UIImage] = []
    @Published var isUploading = false
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // Set the current book for admin operations
    func setCurrentBook(_ book: Book) {
        self.currentBook = book
    }
    
    // Google Sign-In Method
    func signInWithGoogle() async {
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client ID not found"])
            }
            
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            guard let topVC = await getTopViewController() else {
                throw NSError(domain: "GoogleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "Top view controller not found"])
            }
            
            let userResult: GIDSignInResult = try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.main.async {
                    GIDSignIn.sharedInstance.signIn(withPresenting: topVC) { result, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                            return
                        }
                        guard let result = result else {
                            continuation.resume(throwing: NSError(domain: "GoogleSignIn", code: -3, userInfo: [NSLocalizedDescriptionKey: "No sign-in result"]))
                            return
                        }
                        continuation.resume(returning: result)
                    }
                }
            }
            
            guard let idToken = userResult.user.idToken?.tokenString else {
                throw NSError(domain: "GoogleSignIn", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid or expired ID token"])
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: userResult.user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            await MainActor.run {
                self.user = authResult.user
                self.isAuthenticated = true
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.handleSignInError(error)
            }
        }
    }
    
    // Error Handling for Sign-In
    private func handleSignInError(_ error: Error) {
        if let authError = error as NSError?,
           authError.domain == "FIRAuthErrorDomain",
           authError.code == AuthErrorCode.invalidCredential.rawValue {
            self.errorMessage = "Authentication failed. Please try signing in again."
        } else {
            self.errorMessage = error.localizedDescription
        }
        print("Google Sign-In Error: \(error.localizedDescription)")
        self.isAuthenticated = false
    }
    
    // Upload Excerpts for a Book
    func uploadExcerpts(for book: Book) async {
        guard !selectedImages.isEmpty else { return }
        
        await MainActor.run {
            self.isUploading = true
            self.errorMessage = nil
        }
        
        do {
            var excerptURLs: [String] = []
            
            for image in selectedImages {
                let url = try await uploadExcerptImage(image, for: book)
                excerptURLs.append(url)
            }
            
            // Update book's excerpts in Firestore
            try await updateBookExcerpts(book: book, newExcerpts: excerptURLs)
            
            await MainActor.run {
                self.selectedImages.removeAll()
                self.isUploading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to upload excerpts: \(error.localizedDescription)"
                self.isUploading = false
            }
        }
    }
    
    // Upload Individual Excerpt Image
    private func uploadExcerptImage(_ image: UIImage, for book: Book) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "ImageUpload", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not convert image to data"])
        }
        
        let imageName = "\(book.id)_\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child("book_excerpts/\(imageName)")
        
        let _ = try await storageRef.putData(imageData)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    // Update Book's Excerpts in Firestore
    private func updateBookExcerpts(book: Book, newExcerpts: [String]) async throws {
        let bookRef = db.collection("books").document(book.id)
        
        try await bookRef.updateData([
            "excerpts": FieldValue.arrayUnion(newExcerpts)
        ])
    }
    
    // Delete a Specific Excerpt
    func deleteExcerpt(_ excerptURL: String) async {
        guard let book = currentBook else { return }
        
        do {
            let bookRef = db.collection("books").document(book.id)
            
            // Remove excerpt URL from Firestore
            try await bookRef.updateData([
                "excerpts": FieldValue.arrayRemove([excerptURL])
            ])
            
            // Delete image from Storage
            let storageRef = storage.reference(forURL: excerptURL)
            try await storageRef.delete()
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to delete excerpt: \(error.localizedDescription)"
            }
        }
    }
    
    // Get Top View Controller (for Google Sign-In)
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
}
