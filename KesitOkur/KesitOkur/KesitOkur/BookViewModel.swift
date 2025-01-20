import Foundation
import Firebase
import FirebaseStorage

// Firestore'dan kitapları çeken ViewModel
class BooksViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func fetchBooks() {
        isLoading = true
         let db = Firestore.firestore()
         let storage = Storage.storage()
        
        db.collection("books").getDocuments { (snapshot, error) in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if let error = error {
                self.errorMessage = "Veri çekme hatası: \(error.localizedDescription)"
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                self.books = documents.compactMap { doc -> Book? in
                    let data = doc.data()
                    return Book(
                        id: doc.documentID,
                        bookCover: data["bookCover"] as? String ?? "",
                        bookName: data["bookName"] as? String ?? "",
                        authorName: data["authorName"] as? String ?? "",
                        publishYear: data["publishYear"] as? String ?? "",
                        edition: data["edition"] as? String ?? "",
                        pages: data["pages"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        excerpts: data["excerpts"] as? [String] ?? []
                    )
                }
            }
        }
    }
}
