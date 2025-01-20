//
//  FavoritsManager.swift
//  KesitOkur
//
//  Created by Murat Işık on 11.01.2025.
//

import Foundation

class FavoritesManager: ObservableObject {
    @Published var favoriteBooks: Set<Book> = []
    
    func toggleFavorite(book: Book) {
        if favoriteBooks.contains(book) {
            favoriteBooks.remove(book)
        } else {
            favoriteBooks.insert(book)
        }
    }
    
    func isFavorite(book: Book) -> Bool {
        favoriteBooks.contains(book)
    }
}
