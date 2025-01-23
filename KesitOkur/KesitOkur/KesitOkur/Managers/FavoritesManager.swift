import Foundation
import FirebaseFirestore

class FavoritesManager: ObservableObject {
    @Published var favoriteBooks: Set<Book> = []
    
    private let favoritesKey = "favoriteBooks"
    private let db = Firestore.firestore()
    
    init() {
        loadFavorites()
    }
    
    func toggleFavorite(book: Book) {
        if favoriteBooks.contains(book) {
            favoriteBooks.remove(book)
        } else {
            favoriteBooks.insert(book)
        }
        saveFavorites()
    }
    
    func isFavorite(book: Book) -> Bool {
        favoriteBooks.contains(book)
    }
    
    private func saveFavorites() {
        let favoriteIds = favoriteBooks.map { $0.id }
        UserDefaults.standard.set(favoriteIds, forKey: favoritesKey)
    }
    
    private func loadFavorites() {
        guard let favoriteIds = UserDefaults.standard.array(forKey: favoritesKey) as? [String] else {
            return
        }
        
        // Fetch books from Firestore
        fetchFavoriteBooks(ids: favoriteIds)
    }
    
    private func fetchFavoriteBooks(ids: [String]) {
        guard !ids.isEmpty else { return }
        
        // Batch fetch favorite books from Firestore
        db.collection("books")
            .whereField("id", in: ids)
            .getDocuments { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching favorite books: \(error.localizedDescription)")
                    return
                }
                
                let books = querySnapshot?.documents.compactMap { document -> Book? in
                    do {
                        return try document.data(as: Book.self)
                    } catch {
                        print("Error decoding book: \(error.localizedDescription)")
                        return nil
                    }
                } ?? []
                
                DispatchQueue.main.async {
                    self.favoriteBooks = Set(books)
                }
            }
    }
}