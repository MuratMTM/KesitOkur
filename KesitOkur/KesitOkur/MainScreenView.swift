//
//  MainScreenVİew.swift
//  KesitOkur
//
//  Created by Murat Işık on 31.08.2024.
//

import SwiftUI

struct MainScreenView: View {
    let books: [Book] = BookList().books

    var body: some View {
        NavigationView {
            List(books) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    HStack(spacing: 25) {
                        AsyncImage(url: URL(string: book.bookCover)) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 75, height: 100)
                        } placeholder: {
                            ProgressView()
                        }
                        .cornerRadius(10)

                        VStack(alignment: .leading) {
                            Text(book.bookName)
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            Text(book.authorName)
                                .font(.caption)
                                
                                .italic()
                            Text("Yayın Yılı: \(book.publishYear)")
                                .font(.caption)
                                .italic()
                            Text("Baskı Sayısı: \(book.edition)th")
                                .font(.caption)
                                .italic()
                            
                            Text("Sayfa: \(book.pages)")
                                .font(.caption)
                                .italic()
                                .padding(.bottom,5)
                            Text(book.description)
                                .font(.caption2)
                                .lineLimit(3)
                        }
                    }
                }
            }
            .navigationTitle("Kitaplarım")
        }
    }
}

struct BookDetailView: View {
    let book: Book

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 12) {
                AsyncImage(url: URL(string: book.bookCover)){ image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth:.infinity)
                        .frame(height:300)
                } placeholder: {
                    ProgressView()
                }
                .cornerRadius(10)
                    

                Text(book.bookName)
                    .font(.title)
                    .multilineTextAlignment(.center)
                  
                    .fontWeight(.bold)
                    .padding(.horizontal,20)

                Text(book.authorName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                   

               
                    

                Text(book.description)
                    .font(.body)
                    .padding(.horizontal,8)
                    
            }
        }
        
    }
}

#Preview {
    
    MainScreenView()
}
