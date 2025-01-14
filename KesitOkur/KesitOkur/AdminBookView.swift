import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore

struct AdminBookView: View {
    let book: Book
    @StateObject private var viewModel = AdminBookViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [
                    Color(red: 1, green: 0.85, blue: 0.4),
                    Color.white
                ]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Book Info
                        BookHeaderView(book: book)
                        
                        // Current Excerpts
                        if !book.excerpts.isEmpty {
                            ExcerptsList(excerpts: book.excerpts, onDelete: viewModel.deleteExcerpt)
                        }
                        
                        // Add New Excerpts
                        PhotosPicker(selection: $viewModel.selectedItems,
                                   maxSelectionCount: 10,
                                   matching: .images) {
                            AddExcerptsButton()
                        }
                        
                        if viewModel.isUploading {
                            ProgressView("Yükleniyor...")
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Alıntı Yönetimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
            .alert("Hata", isPresented: $viewModel.showError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Bir hata oluştu")
            }
        }
        .onAppear {
            viewModel.setCurrentBook(book)
        }
    }
}

// Supporting Views
struct BookHeaderView: View {
    let book: Book
    
    var body: some View {
        VStack(spacing: 10) {
            AsyncImage(url: URL(string: book.bookCover)) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(height: 150)
            } placeholder: {
                ProgressView()
            }
            
            Text(book.bookName)
                .font(.title2)
                .bold()
            
            Text(book.authorName)
                .font(.subheadline)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
    }
}

struct ExcerptsList: View {
    let excerpts: [String]
    let onDelete: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mevcut Alıntılar")
                .font(.headline)
            
            ForEach(excerpts, id: \.self) { excerpt in
                ExcerptRow(imageURL: excerpt, onDelete: {
                    onDelete(excerpt)
                })
            }
        }
    }
}

struct ExcerptRow: View {
    let imageURL: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: imageURL)) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(height: 60)
            } placeholder: {
                ProgressView()
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
    }
}

struct AddExcerptsButton: View {
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
            Text("Yeni Alıntı Ekle")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
}

#Preview {
    AdminBookView()
}
