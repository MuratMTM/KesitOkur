//
//  SearchTabView.swift
//  KesitOkur
//
//  Created by Murat Işık on 11.01.2025.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel: BooksViewModel
    @State private var searchText = ""
    @State private var isSearching = false
    
    var filteredBooks: [Book] {
        if searchText.isEmpty {
            return viewModel.books
        } else {
            return viewModel.books.filter { book in
                book.bookName.localizedCaseInsensitiveContains(searchText) ||
                book.authorName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1, green: 0.85, blue: 0.4),  // Warm yellow
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Kitap veya yazar ara...", text: $searchText)
                            .foregroundColor(.black)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.horizontal)
                    
                    if isSearching {
                        Button(action: {
                            searchText = ""
                            isSearching = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                         to: nil, from: nil, for: nil)
                        }) {
                            Text("İptal")
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing)
                        .transition(.move(edge: .trailing))
                        .animation(.default, value: isSearching)
                    }
                }
                
                if filteredBooks.isEmpty {
                    EmptySearchView(searchText: searchText)
                } else {
                    // Search results
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(filteredBooks) { book in
                                BookCardView(book: book)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("Kitap Ara")
        .onTapGesture {
            isSearching = true
        }
    }
}

// Custom SearchBar view
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.black)
                .shadow(color: .black.opacity(0.3), radius: 1)
            
            TextField("Kitap veya yazar ara...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.black)
                .accentColor(.black)
                .shadow(color: .black.opacity(0.2), radius: 2)
                .tint(.black)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.black)
                        .shadow(color: .black.opacity(0.3), radius: 1)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// Empty search results view
struct EmptySearchView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.customText)
            
            Group {
                if searchText.isEmpty {
                    Text("Kitap veya yazar aramak için yazın")
                } else {
                    Text("'\(searchText)' için sonuç bulunamadı")
                }
            }
            .font(.title2)
            .foregroundColor(.customText)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
    }
}
