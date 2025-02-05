import SwiftUI
import Kingfisher
import Firebase

struct FavoritePageView: View {
    @StateObject private var favoritesManager = FavoritesManager()
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1, green: 0.85, blue: 0.4),  // Warm yellow
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
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
            }
            .navigationTitle("Favoriler")
        }
        .environmentObject(favoritesManager)
    }
}

struct FavoriteQuotesView: View {
    @ObservedObject var favoritesManager: FavoritesManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                if favoritesManager.favoriteQuotes.isEmpty {
                    Text("Henüz favori alıntınız yok")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(Array(favoritesManager.favoriteQuotes), id: \.id) { quote in
                        QuoteItemView(quote: quote, favoritesManager: favoritesManager)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
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
                    .cornerRadius(10)
            }
            
            Spacer()
            
            Button(action: {
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
            }) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct FavoriteBooksView: View {
    @ObservedObject var favoritesManager: FavoritesManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 15) {
                if favoritesManager.favoriteBooks.isEmpty {
                    Text("Henüz favori kitabınız yok")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(Array(favoritesManager.favoriteBooks), id: \.id) { book in
                        BookItemView(book: book, favoritesManager: favoritesManager)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct BookItemView: View {
    let book: Book
    @ObservedObject var favoritesManager: FavoritesManager

    var body: some View {
        HStack(spacing: 15) {
            if let url = URL(string: book.bookCover) {
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 120)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(book.bookName)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(book.authorName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                favoritesManager.toggleFavoriteBook(book: book)
            }) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    FavoritePageView()
}
