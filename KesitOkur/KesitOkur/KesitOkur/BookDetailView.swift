import SwiftUI

struct BookDetailView: View {
    let book: Book
    @State private var showExcerpts = false
    @State private var showQuotes = false
    @EnvironmentObject var favoritesManager: FavoritesManager
    @State private var quotes: [Quote] = []
    
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
                    // Book cover and details
                    AsyncImage(url: URL(string: book.bookCover)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(15)
                    } placeholder: {
                        ProgressView()
                    }
                    
                    Text(book.bookName)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Text(book.authorName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(book.description)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding()
                    
                    // Add Excerpts Button
                    if !book.excerpts.isEmpty {
                        Button(action: {
                            showExcerpts = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Alıntılar")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showExcerpts) {
            ExcerptsView(book: book)
        }
        .sheet(isPresented: $showQuotes) {
            QuotesGalleryView(book: book, quotes: $quotes)
        }
        .onAppear {
            // Fetch quotes for the specific book
            fetchQuotes()
        }
    }
    
    private func fetchQuotes() {
        // Use the excerpts directly from the book model
        if !book.excerpts.isEmpty {
            self.quotes = book.excerpts.map { excerptUrl in
                Quote(
                    id: UUID().uuidString,
                    url: excerptUrl,
                    text: "", // You might want to add text if available
                    author: nil,
                    isFavorite: false
                )
            }
        } else {
            print("No quotes found for book: \(book.bookName)")
        }
    }
    
    struct QuotesResponse: Codable {
        let quotes: [QuoteData]
        let totalQuotes: Int
        let bookName: String
    }
    
    struct QuoteData: Codable {
        let url: String
        let uploadedAt: String?
        let tags: [String]?
    }
}

struct QuotesGalleryView: View {
    let book: Book
    @Binding var quotes: [Quote]
    @State private var currentQuoteIndex = 0
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        VStack {
            // Quote Counter
            HStack {
                Spacer()
                Text("\(currentQuoteIndex + 1)/\(quotes.count)")
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
            
            // Quote Gallery
            TabView(selection: $currentQuoteIndex) {
                ForEach(Array(quotes.enumerated()), id: \.offset) { index, quote in
                    VStack {
                        AsyncImage(url: URL(string: quote.url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(15)
                                .padding()
                        } placeholder: {
                            ProgressView()
                        }
                        
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
        if let index = quotes.firstIndex(where: { $0.url == quote.url }) {
            quotes[index].isFavorite.toggle()
            
            if quotes[index].isFavorite {
                favoritesManager.addQuoteToFavorites(quote, book: book)
            } else {
                favoritesManager.removeQuoteFromFavorites(quote)
            }
        }
    }
    
    private func isQuoteFavorite(_ quote: Quote) -> Bool {
        quotes.first(where: { $0.url == quote.url })?.isFavorite ?? false
    }
}
