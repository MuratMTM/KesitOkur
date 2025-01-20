import SwiftUI

struct ExcerptsView: View {
    let book: Book
    @Environment(\.dismiss) var dismiss
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Excerpts Gallery
            TabView(selection: $currentIndex) {
                ForEach(Array(book.excerpts.enumerated()), id: \.element) { index, excerptURL in
                    AsyncImage(url: URL(string: excerptURL)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    } placeholder: {
                        ProgressView()
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            
            // Close Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Page indicator
                    Text("\(currentIndex + 1) / \(book.excerpts.count)")
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer()
            }
        }
    }
}

// Fixed Preview with sample book data
#Preview {
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