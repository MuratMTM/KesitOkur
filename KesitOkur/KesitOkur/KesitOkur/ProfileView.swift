//
//  ProfilePageView.swift
//  KesitOkur
//
//  Created by Murat Işık on 3.01.2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ProfileView: View {
    @State private var isEditing = false
    @State private var showingLogoutAlert = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1, green: 0.85, blue: 0.4),  // Warm yellow
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
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
                    .background(Color.customCard)
                    .cornerRadius(15)
                    .shadow(color: .customShadow, radius: 8)
                    .padding(.horizontal)
                    
                    // Statistics Section
                    VStack(spacing: 15) {
                        Text("İstatistikler")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.black)
                        
                        HStack(spacing: 30) {
                            StatisticView(title: "Favoriler", value: "12")
                            StatisticView(title: "Okunanlar", value: "5")
                            StatisticView(title: "İncelemeler", value: "3")
                        }
                    }
                    .padding()
                    .background(Color.customCard)
                    .cornerRadius(15)
                    .shadow(color: .customShadow, radius: 8)
                    .padding(.horizontal)
                    
                    // Buttons
                    VStack(spacing: 20) {
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
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    
                    if authManager.isAdmin {
                        NavigationLink(destination: AdminBooksListView()) {
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
                        .padding()
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
                    try Auth.auth().signOut()
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
            ProfileEditView()
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
                .foregroundColor(.customText)
            Spacer()
            Text(value)
                .foregroundColor(.customSecondaryText)
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
                .bold()
                .foregroundColor(.black)
            Text(title)
                .font(.caption)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.3))
        }
    }
}

struct ProfileEditView: View {
    @StateObject private var authManager = AuthManager()
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var errorMessage: String?
    @State private var emailVerificationSent = false
    
    init() {
        let currentUser = Auth.auth().currentUser
        _firstName = State(initialValue: currentUser?.displayName?.components(separatedBy: " ").first ?? "")
        _lastName = State(initialValue: currentUser?.displayName?.components(separatedBy: " ").last ?? "")
        _email = State(initialValue: currentUser?.email ?? "")
    }
    
    var body: some View {
        Form {
            TextField("First Name", text: $firstName)
            TextField("Last Name", text: $lastName)
            TextField("Email", text: $email)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            if emailVerificationSent {
                Text("Email verification sent. Please check your email.")
                    .foregroundColor(.green)
            }
            
            Button("Save Profile") {
                saveProfile()
            }
        }
    }
    
    
    private func saveProfile() {
        Task { @MainActor in
            guard let user = Auth.auth().currentUser else { return }
            
            do {
                // Update Firebase Authentication profile
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = "\(firstName) \(lastName)"
                try await changeRequest.commitChanges()
                
                // Update Firestore user document
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(user.uid)
                
                try await userRef.updateData([
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email
                ])
                
                // Handle email update
                if user.email != email {
                    await handleEmailUpdate(user: user, newEmail: email)
                }
                
                // Success handling
                errorMessage = nil
                
            } catch {
                errorMessage = error.localizedDescription
                print("Error saving profile: \(error.localizedDescription)")
            }
        }
    }
    
    private func handleEmailUpdate(user: User, newEmail: String) async {
        do {
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
            
            // Optional: Additional UI feedback
            await MainActor.run {
                emailVerificationSent = true
            }
        } catch {
            await MainActor.run {
                errorMessage = "Email verification failed: \(error.localizedDescription)"
                emailVerificationSent = false
            }
        }
    }
    
}
