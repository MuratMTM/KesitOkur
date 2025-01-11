import Foundation
import Firebase
import FirebaseFirestore

class BooksViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func fetchBooks() {
        isLoading = true
        errorMessage = nil
        
        db.collection("books").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Veri çekme hatası: \(error.localizedDescription)"
                    print(self.errorMessage ?? "")
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
                        bookCover: data["bookCover"] as? String ?? "",
                        bookName: data["bookName"] as? String ?? "",
                        authorName: data["authorName"] as? String ?? "",
                        publishYear: data["publishYear"] as? String ?? "",
                        edition: data["edition"] as? String ?? "",
                        pages: data["pages"] as? String ?? "",
                        description: data["description"] as? String ?? ""
                    )
                }
            }
        }
    }
} 