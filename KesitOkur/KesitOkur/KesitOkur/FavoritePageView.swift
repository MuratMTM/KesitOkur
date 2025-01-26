import SwiftUI
import Kingfisher
import Firebase

struct FavoritePageView: View {
    @StateObject private var favoritesManager = FavoritesManager()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            VStack {
                Picker("Favorites", selection: $selectedTab) {
                    Text("Kitaplar").tag(0)
                    Text("Alıntılar").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedTab == 0 {
                    FavoriteBooksView(favoritesManager: favoritesManager)
                } else {
                    FavoriteQuotesView(favoritesManager: favoritesManager)
                }
            }
            .navigationTitle("Favoriler")
        }
        .environmentObject(favoritesManager)
    }
}

struct FavoriteQuotesView: View {
    @ObservedObject var favoritesManager: FavoritesManager

    var body: some View {
        List {
            if favoritesManager.favoriteQuotes.isEmpty {
                Text("Henüz favori alıntınız yok")
            } else {
                ForEach(Array(favoritesManager.favoriteQuotes), id: \.id) { quote in
                    QuoteItemView(quote: quote, favoritesManager: favoritesManager)
                }
            }
        }
    }
}

struct QuoteItemView: View {
    let quote: Quote
    @ObservedObject var favoritesManager: FavoritesManager

    var body: some View {
        HStack {
            if let url = URL(string: quote.url) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
            }
            Text(quote.text)
            Button("Sil") {
                // Create a dummy book if no book is associated
                let dummyBook = Book(
                    id: "dummy_book_id", 
                    bookCover: "", 
                    bookName: "Dummy Book", 
                    authorName: "Unknown", 
                    publishYear: "", 
                    edition: "", 
                    pages: "", 
                    description: "", 
                    excerpts: []
                )
                favoritesManager.toggleFavoriteQuote(quote: quote, book: dummyBook)
            }
        }
    }
}

struct FavoriteBooksView: View {
    @ObservedObject var favoritesManager: FavoritesManager

    var body: some View {
        List {
            if favoritesManager.favoriteBooks.isEmpty {
                Text("Henüz favori kitabınız yok")
            } else {
                ForEach(Array(favoritesManager.favoriteBooks), id: \.id) { book in
                    BookItemView(book: book, favoritesManager: favoritesManager)
                }
            }
        }
    }
}

struct BookItemView: View {
    let book: Book
    @ObservedObject var favoritesManager: FavoritesManager

    var body: some View {
        HStack {
            if let url = URL(string: book.bookCover) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 150)
            }

            VStack(alignment: .leading) {
                Text(book.bookName)
                Text(book.authorName)
            }
            Button("Sil") {
                favoritesManager.toggleFavoriteBook(book: book)
            }
        }
    }
}

#Preview {
    FavoritePageView()
}
