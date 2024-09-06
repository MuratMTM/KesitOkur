//
//  Book.swift
//  KesitOkur
//
//  Created by Murat Işık on 25.08.2024.
//

import Foundation

struct Book: Identifiable, Decodable {
    var id = UUID()
    let bookCover: String
    let bookName: String
    let authorName: String
    let publishYear: String
    let edition: String
    let pages: String
    let description: String
    
    
}

func getBooks() async throws -> Book {
    //continue later...
    let endpoint: String = ""
    guard let url = URL(string: endpoint) else {throw BookError.invalidURl}
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else{
        throw BookError.invalidResponse
    }
    do {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Book.self, from: data)
    } catch  {
        throw BookError.invalidData
    }
}

enum BookError: Error {
    case invalidURl
    case invalidResponse
    case invalidData
}
