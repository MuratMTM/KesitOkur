import SwiftUI
import Combine
import FirebaseStorage

struct ExcerptsView: View {
    let book: Book
    @Environment(\.presentationMode) var presentationMode
    @State private var currentIndex = 0
    @State private var validExcerpts: [String] = []
    @State private var excerptImages: [UIImage] = []
    @State private var isLoading = true
    @State private var loadingError: Error?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView("Resimler yükleniyor...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            } else if let error = loadingError {
                Text("Yükleme Hatası: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else if !excerptImages.isEmpty {
                VStack {
                    TabView(selection: $currentIndex) {
                        ForEach(excerptImages.indices, id: \.self) { index in
                            Image(uiImage: excerptImages[index])
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(10)
                                .shadow(radius: 10)
                                .padding()
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        .padding()
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) / \(excerptImages.count)")
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            } else {
                Text("Görüntülenecek alıntı bulunamadı")
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            loadExcerptImages()
        }
    }
    
    private func loadExcerptImages() {
        isLoading = true
        loadingError = nil
        excerptImages = []
        
        // Fetch image URLs for the book
        fetchExcerptImageURLs { urls in
            // Download images concurrently
            let group = DispatchGroup()
            var downloadedImages: [UIImage] = []
            
            for url in urls {
                group.enter()
                downloadImage(from: url) { image in
                    if let image = image {
                        downloadedImages.append(image)
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.excerptImages = downloadedImages
                self.isLoading = false
                
                if downloadedImages.isEmpty {
                    self.loadingError = NSError(domain: "ImageLoadingError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Hiçbir resim yüklenemedi"])
                }
            }
        }
    }
    
    private func fetchExcerptImageURLs(completion: @escaping ([URL]) -> Void) {
        let storage = Storage.storage()
        let bookQuotesRef = storage.reference().child("quotes/\(book.id)")
        
        bookQuotesRef.listAll { result, error in
            // Handle potential errors first
            if let error = error {
                print("🔥 Kitap alıntı resimleri listelenemedi: \(error.localizedDescription)")
                completion([])
                return
            }
            
            // Safely unwrap result
            guard let result = result else {
                print("❌ No storage list result returned")
                completion([])
                return
            }
            
            // Fetch download URLs for all items
            let urlFetchGroup = DispatchGroup()
            var imageUrls: [URL] = []
            
            // Check if there are any items before processing
            guard !result.items.isEmpty else {
                print("ℹ️ No image items found for book: \(self.book.bookName)")
                completion([])
                return
            }
            
            for item in result.items {
                urlFetchGroup.enter()
                item.downloadURL { url, error in
                    if let url = url {
                        imageUrls.append(url)
                    } else if let error = error {
                        print("🚫 Error fetching download URL: \(error.localizedDescription)")
                    }
                    urlFetchGroup.leave()
                }
            }
            
            urlFetchGroup.notify(queue: .main) {
                print("📸 Bulunan resim URL'leri: \(imageUrls.count)")
                completion(imageUrls)
            }
        }
    }
    
    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("🔴 Resim indirme hatası: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("❌ Geçersiz resim verisi")
                completion(nil)
                return
            }
            
            completion(image)
        }.resume()
    }
}

struct ExcerptsView_Previews: PreviewProvider {
    static var previews: some View {
        ExcerptsView(book: Book(
            id: "1",
            bookCover: "https://example.com/cover.jpg",
            bookName: "Sample Book",
            authorName: "Sample Author",
            publishYear: "2024",
            edition: "1",
            pages: "200",
            description: "Sample description",
            excerpts: [
                "https://example.com/excerpt1.jpg",
                "https://example.com/excerpt2.jpg"
            ]
        ))
    }
}