import SwiftUI
import SDWebImageSwiftUI

struct BookDetailView: View {
    let book: Book
    @State private var showExcerpts = false
    @State private var showQuotes = false
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1, green: 0.85, blue: 0.4),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    // Existing book cover and details...
                    
                    // Book cover and details
                    WebImage(url: URL(string: book.coverImage))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 300)
                        .cornerRadius(15)
                    
                    Text(book.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(book.description)
                        .font(.body)
                        .padding()
                    
                    // Quotes Button
                    if book.quotes != nil && !book.quotes!.isEmpty {
                        Button(action: {
                            showQuotes = true
                        }) {
                            HStack {
                                Image(systemName: "text.quote")
                                Text("Alıntılar")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Add Excerpts Button
                    Button(action: {
                        showExcerpts = true
                    }) {
                        HStack {
                            Image(systemName: "text.quote")
                            Text("Alıntılar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showExcerpts) {
            ExcerptsView(book: book)
        }
        .sheet(isPresented: $showQuotes) {
            QuotesGalleryView(book: book)
        }
    }
}

struct QuotesGalleryView: View {
    let book: Book
    @State private var currentQuoteIndex = 0
    @State private var favoriteQuotes: [Quote] = []
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        VStack {
            // Quote Counter
            HStack {
                Spacer()
                Text("\(currentQuoteIndex + 1)/\(book.quotes?.count ?? 0)")
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
            
            // Quote Gallery
            TabView(selection: $currentQuoteIndex) {
                ForEach(Array(book.quotes?.enumerated() ?? []), id: \.offset) { index, quote in
                    VStack {
                        WebImage(url: URL(string: quote.url))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(15)
                            .padding()
                        
                        // Favorite Button
                        Button(action: {
                            toggleQuoteFavorite(quote)
                        }) {
                            Image(systemName: isQuoteFavorite(quote) ? "heart.fill" : "heart")
                                .foregroundColor(isQuoteFavorite(quote) ? .red : .gray)
                        }
                        .padding()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .never))
        }
    }
    
    private func toggleQuoteFavorite(_ quote: Quote) {
        if isQuoteFavorite(quote) {
            favoritesManager.removeQuoteFromFavorites(quote)
        } else {
            favoritesManager.addQuoteToFavorites(quote, book: book)
        }
    }
    
    private func isQuoteFavorite(_ quote: Quote) -> Bool {
        favoritesManager.favoriteQuotes.contains { $0.url == quote.url }
    }
}