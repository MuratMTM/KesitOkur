import SwiftUI

struct MainScreenView: View {
    let books: [Book] = BookList().books
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka Plan Renk Gradyanı
                RadialGradient(
                    gradient: Gradient(colors: [.blue, .green]),
                    center: .bottom,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea()

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
                                    .cornerRadius(5)
                                    
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
                                            .multilineTextAlignment(.leading)
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
               
                // TabView: Butonlar
                VStack {
                    
                    TabView {
                       
                        // Profil Butonu
                        NavigationLink(destination: ProfilePageView()) {
                         
                        }
                        .tabItem {
                            Image(systemName: "person.circle.fill")
                            Text("Profil")
                        }
                        
                        // Favoriler Butonu
                        NavigationLink(destination: FavoritePageView()) {
                            
                        }
                        .tabItem {
                            Image(systemName: "star.fill")
                            Text("Favoriler")
                        }

                        // Ayarlar Butonu
                        NavigationLink(destination: SettingsPageView()) {
                           
                        }
                        .tabItem {
                            Image(systemName: "gearshape.fill")
                            Text("Ayarlar")
                        }
                    }
        
                    .accentColor(.blue) // TabView renk ayarı
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(20)
                    
                    
                }
                    
            }
        }
    }
}

struct BookDetailView: View {
    let book: Book
    
    var body: some View {
        ZStack {
            // Arka Plan Gradyanı
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

