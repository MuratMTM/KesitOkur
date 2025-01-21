import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var birthDate = Date()
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient matching app theme
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
                            Text("Yeni Hesap Oluştur")
                                .font(.title)
                                .fontWeight(.bold)
                                .padding(.top, 50)
                            
                            // Sign up form
                            VStack(spacing: 15) {
                                TextField("Adı", text: $firstName)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textInputAutocapitalization(.words)
                                    .foregroundColor(.black)
                                    .frame(width: geometry.size.width * 0.8)
                                
                                TextField("Soyadı", text: $lastName)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textInputAutocapitalization(.words)
                                    .foregroundColor(.black)
                                    .frame(width: geometry.size.width * 0.8)
                                
                                TextField("E-posta", text: $email)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .foregroundColor(.black)
                                    .frame(width: geometry.size.width * 0.8)
                                
                                SecureField("Şifre", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .foregroundColor(.black)
                                    .frame(width: geometry.size.width * 0.8)
                                
                                SecureField("Şifreyi Tekrarla", text: $confirmPassword)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .foregroundColor(.black)
                                    .frame(width: geometry.size.width * 0.8)
                                
                                // Date Picker for birth date
                                DatePicker(
                                    "Doğum Tarihi",
                                    selection: $birthDate,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.1), radius: 3)
                                .frame(width: geometry.size.width * 0.8)
                            }
                            .frame(maxWidth: min(geometry.size.width * 0.85, 400))
                            .padding(.horizontal)
                            
                            // Sign Up Button
                            Button(action: {
                                signUp()
                            }) {
                                Text("Kayıt Ol")
                                    .frame(maxWidth: min(geometry.size.width * 0.85, 400))
                                    .frame(height: 50)
                                    .background(Color.yellow.opacity(0.8))
                                    .foregroundColor(.black)
                                    .cornerRadius(10)
                                    .font(.headline)
                            }
                            .padding(.horizontal)
                            
                            Button("Zaten hesabın var mı? Giriş yap") {
                                dismiss()
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("İptal") {
                dismiss()
            })
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func signUp() {
        guard password == confirmPassword else {
            showError = true
            errorMessage = "Şifreler eşleşmiyor"
            return
        }
        
        Task {
            do {
                try await authManager.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    birthDate: birthDate
                )
                dismiss()
            } catch {
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthManager())
    }
}
