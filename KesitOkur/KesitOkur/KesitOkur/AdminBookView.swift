import SwiftUI
import FirebaseAuth
import GoogleSignIn
import FirebaseCore
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
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Google Sign-In Button
                        googleSignInButton
                        
                        // Error Message
                        errorMessageView
                        
                        BookHeaderView(book: book)
                        
                        // Current Excerpts
                        excerptsList
                        
                        // Add New Excerpts Button
                        addExcerptsButton
                        
                        // Upload Progress
                        uploadProgressView
                    }
                    .padding()
                }
            }
            .navigationConfiguration {
                dismiss()
            }
            
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImages: $viewModel.selectedImages)
            }
            .onChange(of: viewModel.selectedImages) { _ in
                Task {
                    await viewModel.uploadExcerpts(for: book)
                }
            }
        }
        .onAppear {
            viewModel.setCurrentBook(book)
        }
    }
    
    // Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1, green: 0.85, blue: 0.4),
                Color.white
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // Google Sign-In Button
    private var googleSignInButton: some View {
        Button("Google ile Giriş Yap") {
            Task {
                await viewModel.signInWithGoogle()
            }
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
    
    // Error Message View
    private var errorMessageView: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    // Excerpts List
    private var excerptsList: some View {
        Group {
            if !book.excerpts.isEmpty {
                ExcerptsList(excerpts: book.excerpts) { url in
                    Task {
                        await viewModel.deleteExcerpt(url)
                    }
                }
            }
        }
    }
    
    // Add Excerpts Button
    private var addExcerptsButton: some View {
        Button(action: {
            showImagePicker = true
        }) {
            AddExcerptsButton()
        }
    }
    
    // Upload Progress View
    private var uploadProgressView: some View {
        Group {
            if viewModel.isUploading {
                ProgressView("Yükleniyor...")
            }
        }
    }
}

// Navigation Configuration Extension
extension View {
    func navigationConfiguration(dismiss: @escaping () -> Void) -> some View {
        self
            .navigationTitle("Alıntı Yönetimi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
    }
}

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
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(10)
        }
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
    AdminBookView(book: Book(
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
