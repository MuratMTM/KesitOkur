import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore

@MainActor
class AdminBookViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var isUploading = false
    @Published var showError = false
    @Published var errorMessage: String?
    
    private var currentBook: Book?
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    func setCurrentBook(_ book: Book) {
        self.currentBook = book
    }
    
    func deleteExcerpt(_ excerptURL: String) {
        guard let book = currentBook else { return }
        
        Task {
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
    }
    
    func uploadExcerpts() {
        guard let book = currentBook else { return }
        isUploading = true
        
        Task {
            do {
                var uploadedURLs: [String] = []
                
                for item in selectedItems {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        let storageRef = storage.reference()
                            .child("books")
                            .child(book.id)
                            .child("excerpts")
                            .child(UUID().uuidString + ".jpg")
                        
                        let metadata = StorageMetadata()
                        metadata.contentType = "image/jpeg"
                        
                        let _ = try await storageRef.putDataAsync(data, metadata: metadata)
                        let url = try await storageRef.downloadURL()
                        uploadedURLs.append(url.absoluteString)
                    }
                }
                
                // Update Firestore with new URLs
                let updatedExcerpts = book.excerpts + uploadedURLs
                try await db.collection("books").document(book.id).updateData([
                    "excerpts": updatedExcerpts
                ])
                
                selectedItems = []
                isUploading = false
            } catch {
                isUploading = false
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}
