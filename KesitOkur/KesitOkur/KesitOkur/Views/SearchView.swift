import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: BooksViewModel
    @State private var searchText = ""
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var filteredBooks: [Book] {
        if searchText.isEmpty {
            return viewModel.books
        } else {
            return viewModel.books.filter { book in
                book.bookName.localizedCaseInsensitiveContains(searchText) ||
                book.authorName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [.blue, .green]),
                center: .bottom,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height
            )
            .ignoresSafeArea()
            
            VStack {
                SearchBar(text: $searchText)
                    .padding()
                
                if filteredBooks.isEmpty {
                    EmptySearchView(searchText: searchText)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(filteredBooks) { book in
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
                                        
                                        BookInfoView(book: book)
                                        
                                        FavoriteButton(book: book)
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Kitap Ara")
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Kitap veya yazar ara...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(10)
    }
}

struct EmptySearchView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
            
            Group {
                if searchText.isEmpty {
                    Text("Kitap veya yazar aramak için yazın")
                } else {
                    Text("'\(searchText)' için sonuç bulunamadı")
                }
            }
            .font(.title2)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
    }
} 