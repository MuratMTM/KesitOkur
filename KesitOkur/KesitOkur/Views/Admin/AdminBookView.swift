import SwiftUI
import UIKit
import FirebaseStorage
import FirebaseFirestore

struct AdminBookView: View {
    let book: Book
    @StateObject private var viewModel = AdminBookViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    
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
                            ExcerptsList(excerpts: book.excerpts) { url in
                                Task {
                                    await viewModel.deleteExcerpt(url)
                                }
                            }
                        }
                        
                        // Add New Excerpts Button (iOS 15.4 compatible)
                        Button(action: {
                            showImagePicker = true
                        }) {
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
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImages: $viewModel.selectedImages)
            }
        }
        .onAppear {
            viewModel.setCurrentBook(book)
        }
    }
}

// Custom ImagePicker for iOS 15.4
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
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
                ExcerptRow(imageURL: excerpt) {
                    onDelete(excerpt)
                }
            }
        }
    }
}

struct ExcerptRow: View {
    let imageURL: String
    let onDelete: () -> Void
    @State private var isDeleting = false
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
            } placeholder: {
                ProgressView()
            }
            
            Spacer()
            
            Button {
                onDelete()
            } label: {
                if isDeleting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                } else {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            .disabled(isDeleting)
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