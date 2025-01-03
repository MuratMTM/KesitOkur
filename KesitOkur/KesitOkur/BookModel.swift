//
//  Book.swift
//  KesitOkur
//
//  Created by Murat Işık on 25.08.2024.
//

import Foundation
import Firebase




struct Book: Identifiable, Decodable {
    var id = UUID()
    let bookCover: String
    let bookName: String
    let authorName: String
    let publishYear: String
    let edition: String
    let pages: String
    let description: String
    
    
    func loadJSON() ->[Book]? {
        guard let url = Bundle.main.url(forResource: "kesitokur-app-books", withExtension: "json")
                else {
                    print("JSON dosyası bulunamadı!")
                    return nil
                }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let books = try decoder.decode([Book].self, from: data)
            return books
        } catch{
            print("JSON dosyası bulunamadı!: \(error)")
            return nil
        }
    }
    
    func addBooksToFirestore(books: [Book]) {
        let db = Firestore.firestore()

        for book in books {
            var ref: DocumentReference? = nil
            ref = db.collection("books").addDocument(data: [
                "id": book.id,
                "bookCover": book.bookCover,
                "bookName": book.bookName,
                "authorName": book.authorName,
                "publishYear": book.publishYear,
                "edition": book.edition,
                "pages" : book.edition ,
                "description" : book.description ,
              
                
            ]) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                } else {
                    print("Document added with ID: \(ref!.documentID)")
                }
            }
        }
    }
    
   
}



enum BookError: Error {
    case invalidURl
    case invalidResponse
    case invalidData
  
}
