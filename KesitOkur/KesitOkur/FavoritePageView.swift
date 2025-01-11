//
//  FavoritPageView.swift
//  KesitOkur
//
//  Created by Murat Işık on 3.01.2025.
//

import SwiftUI

struct FavoritePageView: View {
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching other views
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1, green: 0.85, blue: 0.4),  // Warm yellow
                        Color.white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if favoritesManager.favoriteBooks.isEmpty {
                    EmptyFavoriteView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(Array(favoritesManager.favoriteBooks)) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    HStack(spacing: 25) {
                                        AsyncImage(url: URL(string: book.bookCover)) { image in
                                            image
                                                .resizable()
                                                .frame(width: 75, height: 100)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .cornerRadius(5)
                                        
                                        BookInfoView(book: book)
                                        
                                        FavoriteButton(book: book)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.customCard)
                                            .shadow(color: .customShadow, radius: 8, x: 0, y: 4)
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Favoriler")
        }
    }
}

struct EmptyFavoriteView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.15))
            
            Text("Henüz favori kitabınız yok")
                .font(.title2)
                .bold()
                .foregroundColor(.black)
            
            Text("Kitapları favorilere ekleyerek burada görüntüleyebilirsiniz")
                .font(.body)
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.3))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

#Preview {
    FavoritePageView()
        .environmentObject(FavoritesManager())
}
