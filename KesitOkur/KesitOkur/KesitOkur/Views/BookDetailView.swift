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
                    
                    Text(book.authorName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(book.description)
                        .font(.body)
                        .padding()
                    
                    // Quotes Button
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
                    .padding(.horizontal)
                    .opacity(quotes.isEmpty ? 0.3 : 1.0)
                    .disabled(quotes.isEmpty)
                    
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
        // Hardcoded mapping for now - you might want to make this more dynamic
        let quoteDirectoryMap: [String: String] = [
            "Ustalık": "15",
            // Add more mappings as needed
        ]
        
        // Try multiple potential base paths
        let potentialBasePaths = [
            "/Users/muratisik/Desktop/KesitOkur(App)/KesitOkur/KesitOkur/KesitOkur/KesitOkur/quotes",
            Bundle.main.resourcePath ?? "",
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "",
            "/Users/muratisik/Desktop/KesitOkur(App)/KesitOkur/KesitOkur/KesitOkur/KesitOkur"
        ]
        
        // Debug: Print out all potential paths and book details
        print("🔍 Searching for quotes for book: \(book.bookName)")
        print("🔍 Book ID: \(book.id)")
        print("🔍 Potential base paths: \(potentialBasePaths)")
        print("🔍 Quote directory mapping: \(quoteDirectoryMap)")
        
        var quotesPath: String?
        
        // Find the first valid quote directory
        for basePath in potentialBasePaths {
            print("🔎 Checking base path: \(basePath)")
            
            // Try multiple directory finding strategies
            let strategies = [
                // Strategy 1: Use book name mapping
                { () -> String? in
                    guard let bookQuoteDirectory = quoteDirectoryMap[book.bookName] else {
                        print("❌ No quote directory mapping found for book name: \(book.bookName)")
                        return nil
                    }
                    let fullPath = (basePath as NSString).appendingPathComponent(bookQuoteDirectory)
                    return FileManager.default.fileExists(atPath: fullPath) ? fullPath : nil
                },
                
                // Strategy 2: Use book ID
                { () -> String? in
                    let fullPath = (basePath as NSString).appendingPathComponent(book.id)
                    return FileManager.default.fileExists(atPath: fullPath) ? fullPath : nil
                },
                
                // Strategy 3: Try all numeric subdirectories
                { () -> String? in
                    do {
                        let contents = try FileManager.default.contentsOfDirectory(atPath: basePath)
                        let numericDirs = contents.filter { 
                            let path = (basePath as NSString).appendingPathComponent($0)
                            var isDirectory: ObjCBool = false
                            FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
                            return isDirectory.boolValue && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: $0))
                        }
                        
                        // Try the first numeric directory
                        if let firstNumericDir = numericDirs.first {
                            let fullPath = (basePath as NSString).appendingPathComponent(firstNumericDir)
                            return FileManager.default.fileExists(atPath: fullPath) ? fullPath : nil
                        }
                    } catch {
                        print("❌ Error listing directory contents: \(error)")
                    }
                    return nil
                }
            ]
            
            // Try each strategy
            for (index, strategy) in strategies.enumerated() {
                if let foundPath = strategy() {
                    quotesPath = foundPath
                    print("✅ Found quotes path using strategy \(index + 1): \(foundPath)")
                    break
                }
            }
            
            if quotesPath != nil {
                break
            }
        }
        
        guard let quotesPath = quotesPath else {
            print("❌ Could not find quotes directory for book: \(book.bookName)")
            print("❌ Book details: \(book)")
            return
        }
        
        do {
            let fileManager = FileManager.default
            let quotesDirectory = URL(fileURLWithPath: quotesPath)
            let quoteFiles = try fileManager.contentsOfDirectory(
                at: quotesDirectory, 
                includingPropertiesForKeys: nil
            )
            
            quotes = quoteFiles.compactMap { fileURL in
                // Filter for image files
                guard fileURL.pathExtension.lowercased() == "jpg" || 
                      fileURL.pathExtension.lowercased() == "jpeg" ||
                      fileURL.pathExtension.lowercased() == "png" else {
                    return nil
                }
                
                return Quote(
                    url: fileURL.path,
                    text: "Quote from \(book.bookName)", // You might want to add text extraction logic
                    isFavorite: false
                )
            }
            
            print("✅ Found \(quotes.count) quotes for \(book.bookName) in \(quotesPath)")
            print("✅ Quote files: \(quotes.map { $0.url })")
        } catch {
            print("❌ Error fetching quotes for \(book.bookName): \(error)")
            quotes = []
        }
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
