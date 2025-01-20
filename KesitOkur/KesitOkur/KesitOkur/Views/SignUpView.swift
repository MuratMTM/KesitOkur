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
                                .font(.title2)
                                .bold()
                                .padding(.top, 20)
                            
                            // Sign up form
                            VStack(spacing: 15) {
                                TextField("Adı", text: $firstName)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .frame(width: geometry.size.width * 0.8)
                                
                                TextField("Soyadı", text: $lastName)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .frame(width: geometry.size.width * 0.8)
                                
                                TextField("E-posta", text: $email)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .frame(width: geometry.size.width * 0.8)
                                
                                SecureField("Şifre", text: $password)
                                    .textFieldStyle(CustomTextFieldStyle())
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
                            
                            // Sign Up Button
                            Button(action: {
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
                            }) {
                                Text("Kayıt Ol")
                                    .frame(width: geometry.size.width * 0.8)
                                    .padding()
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button("Zaten hesabın var mı? Giriş Yap") {
                                dismiss()
                            }
                            .foregroundColor(.black)
                            .padding(.top)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarItems(leading: Button("İptal") {
                dismiss()
            })
        }
        .alert("Hata", isPresented: $showError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthManager())
} 