//
//  FavoritsManager.swift
//  KesitOkur
//
//  Created by Murat Işık on 11.01.2025.
//

import Foundation
import SwiftUI

class FavoritesManager: ObservableObject {
    @Published var favoriteBooks: Set<Book> = []
    @Published var favoriteQuotes: Set<Quote> = []
    
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
