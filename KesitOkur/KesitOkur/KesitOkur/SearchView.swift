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
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.black)
                    
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Kitap veya yazar ara...")
                                .foregroundColor(.gray)
                        }
                        TextField("", text: $searchText)
                            .foregroundColor(.black)
                    }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            isSearching = false
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                         to: nil, from: nil, for: nil)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding()
                
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

// Empty search results view
struct EmptySearchView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
            
            Group {
                if searchText.isEmpty {
                    Text("Aramak istediğiniz kitap veya yazarı yazın")
                } else {
                    Text("'\(searchText)' için sonuç bulunamadı")
                }
            }
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .padding(.top, 50)
    }
}

#Preview {
    SearchView(viewModel: BooksViewModel())
}
