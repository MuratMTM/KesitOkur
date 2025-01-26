import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore

class FavoritesManager: ObservableObject {
    @Published var favoriteBooks: Set<Book> = []
    @Published var favoriteQuotes: Set<Quote> = []
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    init() {
        fetchFavoriteBooks()
        fetchFavoriteQuotes()
    }
    
    // MARK: - Book Favorites
    
    func addBookToFavorites(_ book: Book) {
        guard let userId = auth.currentUser?.uid else { return }
        
        let bookData: [String: Any] = [
            "id": book.id,
            "title": book.title,
            "author": book.author,
            "coverImage": book.coverImage,
            "description": book.description
        ]
        
        db.collection("users").document(userId).collection("favoriteBooks").document(book.id).setData(bookData) { error in
            if let error = error {
                print("Error adding book to favorites: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.favoriteBooks.insert(book)
                }
            }
        }
    }
    
    func removeBookFromFavorites(_ book: Book) {
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("favoriteBooks").document(book.id).delete { error in
            if let error = error {
                print("Error removing book from favorites: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.favoriteBooks.remove(book)
                }
            }
        }
    }
    
    private func fetchFavoriteBooks() {
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("favoriteBooks").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching favorite books: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.favoriteBooks = Set(documents.compactMap { doc -> Book? in
                let data = doc.data()
                return Book(
                    id: data["id"] as? String ?? "",
                    title: data["title"] as? String ?? "",
                    author: data["author"] as? String ?? "",
                    coverImage: data["coverImage"] as? String ?? "",
                    description: data["description"] as? String ?? ""
                )
            })
        }
    }
    
    // MARK: - Quote Favorites
    
    func addQuoteToFavorites(_ quote: Quote, book: Book) {
        guard let userId = auth.currentUser?.uid else { return }
        
        let quoteData: [String: Any] = [
            "id": quote.id.uuidString,
            "url": quote.url,
            "bookId": book.id
        ]
        
        db.collection("users").document(userId).collection("favoriteQuotes").document(quote.id.uuidString).setData(quoteData) { error in
            if let error = error {
                print("Error adding quote to favorites: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.favoriteQuotes.insert(quote)
                }
            }
        }
    }
    
    func removeQuoteFromFavorites(_ quote: Quote) {
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("favoriteQuotes").document(quote.id.uuidString).delete { error in
            if let error = error {
                print("Error removing quote from favorites: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.favoriteQuotes.remove(quote)
                }
            }
        }
    }
    
    private func fetchFavoriteQuotes() {
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("favoriteQuotes").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching favorite quotes: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.favoriteQuotes = Set(documents.compactMap { doc -> Quote? in
                let data = doc.data()
                return Quote(
                    url: data["url"] as? String ?? "",
                    isFavorite: true
                )
            })
        }
    }
    
    func toggleFavoriteBook(book: Book) {
        if favoriteBooks.contains(book) {
            favoriteBooks.remove(book)
        } else {
            favoriteBooks.insert(book)
        }
    }
    
    func toggleFavoriteQuote(quote: Quote) {
        if favoriteQuotes.contains(quote) {
            favoriteQuotes.remove(quote)
        } else {
            favoriteQuotes.insert(quote)
        }
    }
    
    func isFavoriteBook(book: Book) -> Bool {
        favoriteBooks.contains(book)
    }
    
    func isFavoriteQuote(quote: Quote) -> Bool {
        favoriteQuotes.contains(quote)
    }
    
    func removeBookFromFavorites(_ book: Book) {
        favoriteBooks.remove(book)
    }
    
    func removeQuoteFromFavorites(_ quote: Quote) {
        favoriteQuotes.remove(quote)
    }
}