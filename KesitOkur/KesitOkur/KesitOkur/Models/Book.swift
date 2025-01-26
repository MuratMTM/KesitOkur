import Foundation

struct Quote: Identifiable, Hashable {
    let id = UUID()
    let url: String
    var isFavorite: Bool
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id
    }
}

struct Book: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let author: String
    let coverImage: String // Image name or URL
    let description: String
    var quotes: [Quote]?
    var favoriteQuotes: [Quote]?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Book, rhs: Book) -> Bool {
        lhs.id == rhs.id
    }
}