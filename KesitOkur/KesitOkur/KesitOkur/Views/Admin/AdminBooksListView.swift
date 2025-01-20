import SwiftUI
import FirebaseFirestore

struct AdminBooksListView: View {
    @StateObject private var viewModel = BooksViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
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
                    VStack(spacing: 20) {
                        ForEach(viewModel.books) { book in
                            NavigationLink(destination: AdminBookView(book: book)) {
                                AdminBookRow(book: book)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Kitap Yönetimi")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.fetchBooks()
        }
    }
}

struct AdminBookRow: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: URL(string: book.bookCover)) { image in
                image
                    .resizable()
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
            } placeholder: {
                ProgressView()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.bookName)
                    .font(.headline)
                Text(book.authorName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

#Preview {
    AdminBooksListView()
} 