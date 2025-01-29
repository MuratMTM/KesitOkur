import Foundation

struct Quote: Identifiable, Hashable {
    let id: String
    let url: String
    let text: String
    let author: String?
    var isFavorite: Bool
    
    // Initializer
    init(id: String = UUID().uuidString, url: String, text: String, author: String? = nil, isFavorite: Bool = false) {
        self.id = id
        self.url = url
        self.text = text
        self.author = author
        self.isFavorite = isFavorite
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Quote, rhs: Quote) -> Bool {
        lhs.id == rhs.id
    }
}
