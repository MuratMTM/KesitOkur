import Foundation
import Firebase

struct Book: Identifiable, Hashable {
    let id: String
    let bookCover: String
    let bookName: String
    let authorName: String
    let publishYear: String
    let edition: String
    let pages: String
    let description: String
    
    // Implement hash function
    func hash(into hasher: inout Hasher) {
        // Since id is unique, we only need to hash that
        hasher.combine(id)
    }
    
    // Implement equality
    static func == (lhs: Book, rhs: Book) -> Bool {
        // Two books are equal if they have the same id
        return lhs.id == rhs.id
    }
}



