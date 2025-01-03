import SwiftUI

struct MainScreenView: View {
    let books: [Book] = BookList().books

    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan RadialGradient - Sarıdan beyaza geçiş
                RadialGradient(
                    gradient: Gradient(colors: [.blue, .green]),
                    center: .bottom,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea() // Arka planın tüm ekranı kaplamasını sağlarız
                
                // Kitaplar ve içerikler
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(books) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                HStack(spacing: 25) {
                                    AsyncImage(url: URL(string: book.bookCover)) { image in
                                        image
                                            .resizable()
                                            
                                            .frame(width: 75, height: 100)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .cornerRadius(10)

                                    VStack(alignment: .leading) {
                                        Text(book.bookName)
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(.black)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Text(book.authorName)
                                            .font(.caption)
                                            .italic()
                                            .foregroundStyle(.white)
                                        Text("Yayın Yılı: \(book.publishYear)")
                                            .font(.caption)
                                            .italic()
                                            .foregroundStyle(.black)
                                        Text("Baskı Sayısı: \(book.edition)th")
                                            .font(.caption)
                                            .italic()
                                            .foregroundStyle(.black)
                                        Text("Sayfa: \(book.pages)")
                                            .font(.caption)
                                            .italic()
                                            .padding(.bottom, 5)
                                            .foregroundStyle(.black)
                                        Text(book.description)
                                            .font(.caption2)
                                            .lineLimit(3)
                                            .foregroundStyle(.black)
                                    }
                                }
                                .padding(1)
                                
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Kitaplarım")
            }
        }
    }
}

struct BookDetailView: View {
    let book: Book

    var body: some View {
        ZStack {
            
          
                // Arka plan RadialGradient - Sarıdan beyaza geçiş
                RadialGradient(
                    gradient: Gradient(colors: [.blue, .green]),
                    center: .bottom,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea() // Arka planın tüm ekranı kaplamasını sağlarız
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
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16.0, weight: .bold))
                        .padding(.horizontal, 20)
                    
                    Text(book.authorName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(book.description)
                        .font(.body)
                        .padding(.horizontal, 8)
                }
            }
        }
    }
}

#Preview {
    MainScreenView()
}
