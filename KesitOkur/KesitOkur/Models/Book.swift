import Foundation

struct Book: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let author: String
    let coverImage: String // Image name or URL
    let description: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Book, rhs: Book) -> Bool {
        lhs.id == rhs.id
    }
} 