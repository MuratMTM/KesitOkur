import SwiftUI
import Combine
import FirebaseStorage

// Add a simple image cache to reduce redundant network requests
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    func image(for url: URL) -> UIImage? {
        return cache.object(forKey: url as NSURL)
    }
    
    func cache(image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}

struct ExcerptsView: View {
    let book: Book
    @Environment(\.presentationMode) var presentationMode
    @State private var currentIndex = 0
    @State private var excerptImages: [UIImage] = []
    @State private var isLoading = true
    @State private var loadingError: Error?
    
    // Limit concurrent image downloads to prevent overwhelming the network
    private let imageDownloadQueue = DispatchQueue(label: "com.kesitokur.imageDownloadQueue", attributes: .concurrent)
    
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
        
        fetchExcerptImageURLs { urls in
            // Use a concurrent queue for image downloads
            let group = DispatchGroup()
            var downloadedImages: [UIImage] = []
            
            for url in urls {
                group.enter()
                imageDownloadQueue.async {
                    self.downloadImage(from: url) { image in
                        if let image = image {
                            DispatchQueue.main.async {
                                downloadedImages.append(image)
                            }
                        }
                        group.leave()
                    }
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
            if let error = error {
                print("🔥 Kitap alıntı resimleri listelenemedi: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let result = result else {
                print("❌ No storage list result returned")
                completion([])
                return
            }
            
            guard !result.items.isEmpty else {
                print("ℹ️ No image items found for book: \(self.book.bookName)")
                completion([])
                return
            }
            
            let urlFetchGroup = DispatchGroup()
            var imageUrls: [URL] = []
            
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
        // Check image cache first
        if let cachedImage = ImageCache.shared.image(for: url) {
            completion(cachedImage)
            return
        }
        
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
            
            // Cache the downloaded image
            ImageCache.shared.cache(image: image, for: url)
            
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