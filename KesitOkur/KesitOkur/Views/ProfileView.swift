import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileView: View {
    @State private var isEditing = false
    @State private var showingLogoutAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [.blue, .green]),
                center: .bottom,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Profile Image
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // User Info Section
                    VStack(spacing: 15) {
                        ProfileInfoRow(title: "Ad Soyad", value: "Kullanıcı Adı")
                        ProfileInfoRow(title: "E-posta", value: "user@example.com")
                        ProfileInfoRow(title: "Üyelik Tarihi", value: "17.03.2024")
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Statistics Section
                    VStack(spacing: 15) {
                        Text("İstatistikler")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 30) {
                            StatisticView(title: "Favoriler", value: "12")
                            StatisticView(title: "Okunanlar", value: "5")
                            StatisticView(title: "İncelemeler", value: "3")
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Buttons
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Profili Düzenle")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.5))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Çıkış Yap")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.5))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    if authManager.isAdmin {
                        Button(action: {
                            // Navigate to admin interface
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Yönetici Paneli")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.5))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Profil")
        .alert("Çıkış Yap", isPresented: $showingLogoutAlert) {
            Button("İptal", role: .cancel) { }
            Button("Çıkış Yap", role: .destructive) {
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    // For iOS 15.4+, use the appropriate navigation
                    let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    let window = scene?.windows.first
                    window?.rootViewController = UIHostingController(rootView: LoginPageView())
                } catch {
                    print("Error signing out: \(error.localizedDescription)")
                }
            }
        } message: {
            Text("Çıkış yapmak istediğinizden emin misiniz?")
        }
        .sheet(isPresented: $isEditing) {
            EditProfileView()
        }
    }
}

// Supporting Views
struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [.blue, .green]),
                    center: .bottom,
                    startRadius: 0,
                    endRadius: UIScreen.main.bounds.height
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    TextField("Ad Soyad", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("E-posta", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .padding(.horizontal)
                    
                    Button("Kaydet") {
                        // Handle save
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.5))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarItems(trailing: Button("İptal") {
                dismiss()
            })
        }
    }
} 