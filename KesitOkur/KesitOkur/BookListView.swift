//
//  BookListView.swift
//  KesitOkur
//
//  Created by Murat Işık on 25.08.2024.
//

import SwiftUI

struct BookListView: View {
    @State private var searchText = ""
    @State private var books: [Book] = []

    var body: some View {
        NavigationView {
            List(books) { book in
                // Kitap listesi hücresi
            }
            .searchable(text: $searchText)
        }
        .onAppear {
            searchBooks(query: "swift programming")
        }
    }

    func searchBooks(query: String) {
        let urlString = "https://openlibrary.org/search.json?title=\(query)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { return }

            if let decodedResponse = try? JSONDecoder().decode(SearchResponse.self, from: data) {
                DispatchQueue.main.async {
                    books = decodedResponse.docs
                }
            }
        }.resume()
    }
}

// JSON yanıtı için model
struct SearchResponse: Decodable {
    let docs: [Book]
}


#Preview {
    BookListView()
}




