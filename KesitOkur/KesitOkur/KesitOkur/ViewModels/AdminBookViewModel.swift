import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore

@MainActor
class AdminBookViewModel: ObservableObject {
    @Published var selectedImages: [UIImage] = []
    @Published var isUploading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private var currentBook: Book?
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    func setCurrentBook(_ book: Book) {
        self.currentBook = book
    }
    
    func deleteExcerpt(_ excerptURL: String) async {
        guard let book = currentBook else { return }
        
        do {
            // Delete from Storage
            let storageRef = storage.reference(forURL: excerptURL)
            try await storageRef.delete()
            
            // Update Firestore
            var updatedExcerpts = book.excerpts
            updatedExcerpts.removeAll { $0 == excerptURL }
            
            try await db.collection("books").document(book.id).updateData([
                "excerpts": updatedExcerpts
            ])
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    func uploadExcerpts() async {
        guard let book = currentBook else { return }
        isUploading = true
        
        do {
            var uploadedURLs: [String] = []
            
            for image in selectedImages {
                if let imageData = image.jpegData(compressionQuality: 0.7) {
                    let storageRef = storage.reference()
                        .child("books")
                        .child(book.id)
                        .child("excerpts")
                        .child(UUID().uuidString + ".jpg")
                    
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    
                    let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
                    let url = try await storageRef.downloadURL()
                    uploadedURLs.append(url.absoluteString)
                }
            }
            
            // Update Firestore with new URLs
            let updatedExcerpts = book.excerpts + uploadedURLs
            try await db.collection("books").document(book.id).updateData([
                "excerpts": updatedExcerpts
            ])
            
            selectedImages = []
            isUploading = false
        } catch {
            isUploading = false
            showError = true
            errorMessage = error.localizedDescription
        }
    }
} 