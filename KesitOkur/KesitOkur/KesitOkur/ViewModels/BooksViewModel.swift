import Foundation
import Firebase
import FirebaseFirestore
import FirebaseStorage

class BooksViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func fetchBooks() {
        isLoading = true
        errorMessage = nil
        
        db.collection("books").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Veri çekme hatası: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "Kitap bulunamadı"
                    return
                }
                
                self.books = documents.compactMap { doc -> Book? in
                    let data = doc.data()
                    return Book(
                        id: doc.documentID,
                        title: data["bookName"] as? String ?? "",
                        author: data["authorName"] as? String ?? "",
                        coverImage: data["bookCover"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        quotes: nil,
                        favoriteQuotes: nil,
                        excerpts: data["excerpts"] as? [String] ?? []
                    )
                }
            }
        }
    }
} 