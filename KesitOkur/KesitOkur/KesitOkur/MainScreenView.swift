import SwiftUI
import Firebase

struct MainScreenView: View {
    @StateObject private var viewModel = BooksViewModel()
    @EnvironmentObject var favoritesManager: FavoritesManager
    @EnvironmentObject var authManager: AuthManager
    
    
    init() {
        // Hide the navigation bar when scrolling
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.backgroundColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = nil
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Make TabBar blend with the gradient
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = UIColor(Color(red: 1, green: 0.85, blue: 0.4))
    
        
        // Configure TabBar items colors with shadow
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = CGSize(width: 0, height: 1)
        shadow.shadowBlurRadius = 3
        
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.black,
            .shadow: shadow
        ]
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .black
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = textAttributes
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = .black
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = textAttributes
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    var body: some View {
        TabView {
            // Books Tab
            NavigationView {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1, green: 0.85, blue: 0.4),  // Warm yellow
                            Color.white
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    if viewModel.isLoading {
                        ProgressView("Kitaplar Yükleniyor...")
                    } else {
                        BookListView(books: viewModel.books)
                    }
                }
                .navigationBarTitleDisplayMode(.large) // This will show the large title only at the top
                .navigationTitle("Kitaplarım")
            }
            .tabItem {
                Image(systemName: "book.fill")
                Text("Kitaplar")
            }
            
            // Search Tab
            NavigationView {
                SearchView(viewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
                Text("Ara")
            }
            
            // Favorites Tab
            FavoritePageView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favoriler")
                }
            
            // Profile Tab
            NavigationView {
                ProfileView()
                    .environmentObject(authManager)
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profil")
            }
        }
        .accentColor(.white) // This will make selected tab items white
        .onAppear {
            viewModel.fetchBooks()
        }
    }
}

// Separate the book list into its own view for better organization
    struct BookListView: View {
        let books: [Book]
        @EnvironmentObject var favoritesManager: FavoritesManager
    
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                ForEach(books) { book in
                    BookCardView(book: book)
                }
            }
            .padding()
        }
    }
}

// Separate book card into its own view
struct BookCardView: View {
    let book: Book
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            HStack(spacing: 25) {
                AsyncImage(url: URL(string: book.bookCover)) { image in
                    image
                        .resizable()
                        .frame(width: 75, height: 100)
                } placeholder: {
                    ProgressView()
                }
                .cornerRadius(5)
                .background(Color.gray.opacity(0.1))
                
                BookInfoView(book: book)
                
                FavoriteButton(book: book)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.customCard)
                    .shadow(color: .customShadow, radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal)
        }
    }
}

// Separate book info into its own view
struct BookInfoView: View {
    let book: Book
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.bookName)
                .font(.headline)
                .bold()
                .foregroundColor(.black)
                .lineLimit(3)
                .shadow(color: .black.opacity(0.2), radius: 0.5)
            
            Text(book.authorName)
                .font(.subheadline)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                .shadow(color: .black.opacity(0.2), radius: 0.5)
            
            Group {
                Text("Yayın Yılı: \(book.publishYear)")
                Text("Baskı Sayısı: \(book.edition)th")
                Text("Sayfa: \(book.pages)")
            }
            .font(.caption)
            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.3))
            .shadow(color: .black.opacity(0.2), radius: 0.5)
            
            Text(book.description)
                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                .font(.caption2)
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.3))
                .lineLimit(2)
                .shadow(color: .black.opacity(0.2), radius: 0.5)
        }
    }
}

// Separate favorite button into its own view
struct FavoriteButton: View {
    let book: Book
    @EnvironmentObject private var favoritesManager: FavoritesManager
    var body: some View {
        Button(action: {
            favoritesManager.toggleFavorite(book: book)
        }) {
            Image(systemName: favoritesManager.isFavorite(book: book) ? "heart.fill" : "heart")
                .foregroundColor(favoritesManager.isFavorite(book: book) ? .red : .black)
                .padding(.trailing, 10)
        }
    }
}

struct BookDetailView: View {
    let book: Book
    @State private var showExcerpts = false
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1, green: 0.85, blue: 0.4),  // Warm yellow
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    AsyncImage(url: URL(string: book.bookCover)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                    } placeholder: {
                        ProgressView()
                    }
                    .cornerRadius(10)
                    
                    Text(book.bookName)
                        .font(.title)
                        .bold()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                    
                    Text(book.authorName)
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
                    
                    Text(book.description)
                        .font(.body)
                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.3))
                        .padding(.horizontal)
                    
                    FavoriteButton(book: book)
                        .padding()
                    
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
    }
}

#Preview {
    MainScreenView()
        .environmentObject(FavoritesManager())
}

