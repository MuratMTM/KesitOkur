//
//  FavoritsManager.swift
//  KesitOkur
//
//  Created by Murat Işık on 11.01.2025.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

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
    
    func toggleFavoriteBook(book: Book) {
        if favoriteBooks.contains(book) {
            removeBookFromFavorites(book)
        } else {
            addBookToFavorites(book)
        }
        objectWillChange.send()  // Force UI update
    }
    
    func addBookToFavorites(_ book: Book) {
        guard let userId = auth.currentUser?.uid else { return }
        
        // Update local state immediately for better UI responsiveness
        DispatchQueue.main.async {
            self.favoriteBooks.insert(book)
            self.objectWillChange.send()  // Force UI update
        }
        
        let bookData: [String: Any] = [
            "id": book.id,
            "bookName": book.bookName,
            "authorName": book.authorName,
            "bookCover": book.bookCover,
            "description": book.description,
            "timestamp": FieldValue.serverTimestamp()  // Add timestamp for sorting
        ]
        
        db.collection("users").document(userId).collection("favoriteBooks").document(book.id).setData(bookData) { error in
            if let error = error {
                print("Error adding book to favorites: \(error)")
                // Revert local state if server update fails
                DispatchQueue.main.async {
                    self.favoriteBooks.remove(book)
                    self.objectWillChange.send()  // Force UI update
                }
            }
        }
    }
    
    func removeBookFromFavorites(_ book: Book) {
        guard let userId = auth.currentUser?.uid else { return }
        
        // Update local state immediately for better UI responsiveness
        DispatchQueue.main.async {
            self.favoriteBooks.remove(book)
            self.objectWillChange.send()  // Force UI update
        }
        
        db.collection("users").document(userId).collection("favoriteBooks").document(book.id).delete { error in
            if let error = error {
                print("Error removing book from favorites: \(error)")
                // Revert local state if server update fails
                DispatchQueue.main.async {
                    self.favoriteBooks.insert(book)
                    self.objectWillChange.send()  // Force UI update
                }
            }
        }
    }
    
    private func fetchFavoriteBooks() {
        guard let userId = auth.currentUser?.uid else { return }
        
        // Use real-time listener
        db.collection("users").document(userId).collection("favoriteBooks")
            .order(by: "timestamp", descending: true)  // Sort by timestamp
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                guard let documents = snapshot?.documents else {
                    print("Error fetching favorite books: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                DispatchQueue.main.async {
                    self.favoriteBooks = Set(documents.compactMap { doc -> Book? in
                        let data = doc.data()
                        return Book(
                            id: data["id"] as? String ?? "",
                            bookCover: data["bookCover"] as? String ?? "",
                            bookName: data["bookName"] as? String ?? "",
                            authorName: data["authorName"] as? String ?? "",
                            publishYear: "",
                            edition: "",
                            pages: "",
                            description: data["description"] as? String ?? "",
                            excerpts: []
                        )
                    })
                    self.objectWillChange.send()  // Force UI update
                }
        }
    }
    
    // MARK: - Quote Favorites
    
    func addQuoteToFavorites(_ quote: Quote, book: Book) {
        guard let userId = auth.currentUser?.uid else { return }
        
        let quoteData: [String: Any] = [
            "id": quote.id,
            "url": quote.url,
            "text": quote.text,
            "bookId": book.id
        ]
        
        db.collection("users").document(userId).collection("favoriteQuotes").document(quote.id).setData(quoteData) { error in
            if let error = error {
                print("Error adding quote to favorites: \(error)")
            } else {
                DispatchQueue.main.async {
                    var updatedQuote = quote
                    updatedQuote.isFavorite = true
                    self.favoriteQuotes.insert(updatedQuote)
                }
            }
        }
    }
    
    func removeQuoteFromFavorites(_ quote: Quote) {
        guard let userId = auth.currentUser?.uid else { return }
        
        db.collection("users").document(userId).collection("favoriteQuotes").document(quote.id).delete { error in
            if let error = error {
                print("Error removing quote from favorites: \(error)")
            } else {
                DispatchQueue.main.async {
                    var updatedQuote = quote
                    updatedQuote.isFavorite = false
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
                    id: data["id"] as? String ?? UUID().uuidString,
                    url: data["url"] as? String ?? "",
                    text: data["text"] as? String ?? "",
                    isFavorite: true
                )
            })
        }
    }
    
    func toggleFavoriteQuote(quote: Quote, book: Book) {
        if favoriteQuotes.contains(quote) {
            removeQuoteFromFavorites(quote)
        } else {
            addQuoteToFavorites(quote, book: book)
        }
    }
    
    func isFavoriteBook(book: Book) -> Bool {
        favoriteBooks.contains(book)
    }
    
    func isFavoriteQuote(quote: Quote) -> Bool {
        favoriteQuotes.contains(quote)
    }
}
