import Foundation

class FavoritesManager: ObservableObject {
    @Published var favoriteBooks: Set<Book> = []
    
    private let favoritesKey = "favoriteBooks"
    
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
        favoriteBooks = Set()
    }
} 