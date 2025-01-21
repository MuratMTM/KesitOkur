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
                        // Book Infofunc signInWithGoogle() {
                            Task {
                                do {
                                    guard let clientID = FirebaseApp.app()?.options.clientID else {
                                        self.errorMessage = "Error getting client ID"
                                        return
                                    }
                                    
                                    let config = GIDConfiguration(clientID: clientID)
                                    GIDSignIn.sharedInstance.configuration = config
                                    
                                    guard let topVC = await getTopViewController() else {
                                        self.errorMessage = "Could not get top view controller"
                                        return
                                    }
                                    
                                    let userResult: GIDSignInResult = try await withCheckedThrowingContinuation { continuation in
                                        DispatchQueue.main.async {
                                            GIDSignIn.sharedInstance.signIn(withPresenting: topVC) { result, error in
                                                if let error = error {
                                                    continuation.resume(throwing: error)
                                                    return
                                                }
                                                guard let result = result else {
                                                    continuation.resume(throwing: NSError(domain: "GoogleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "No sign-in result"]))
                                                    return
                                                }
                                                continuation.resume(returning: result)
                                            }
                                        }
                                    }
                                    
                                    // Add additional validation for ID token
                                    guard let idToken = userResult.user.idToken?.tokenString else {
                                        throw NSError(domain: "GoogleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid or expired ID token"])
                                    }
                                    
                                    let credential = GoogleAuthProvider.credential(
                                        withIDToken: idToken,
                                        accessToken: userResult.user.accessToken.tokenString
                                    )
                                    
                                    // Add retry mechanism for credential sign-in
                                    do {
                                        let authResult = try await Auth.auth().signIn(with: credential)
                                        await MainActor.run {
                                            self.user = authResult.user
                                            self.isAuthenticated = true
                                        }
                                    } catch {
                                        // Specific handling for credential-related errors
                                        if let authError = error as NSError?,
                                           authError.domain == "FIRAuthErrorDomain",
                                           authError.code == AuthErrorCode.invalidCredential.rawValue {
                                            // Attempt re-authentication or prompt user to sign in again
                                            self.errorMessage = "Authentication failed. Please try signing in again."
                                        } else {
                                            self.errorMessage = error.localizedDescription
                                        }
                                        throw error
                                    }
                                    
                                } catch {
                                    await MainActor.run {
                                        self.errorMessage = error.localizedDescription
                                        print("Google Sign-In Error: \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                        BookHeaderView(book: book)
                        
                        // Current Excerpts
                        if !book.excerpts.isEmpty {
                            ExcerptsList(excerpts: book.excerpts) { url in
                                                           Task {
                                                               await viewModel.deleteExcerpt(url)
                                                           }
                                                       }
                        }
                        
                        // Add New Excerpts
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
            }.sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImages: $viewModel.selectedImages)
            }
        }
        .onAppear {
            viewModel.setCurrentBook(book)
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
                
            }.disabled(isDeleting)
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
