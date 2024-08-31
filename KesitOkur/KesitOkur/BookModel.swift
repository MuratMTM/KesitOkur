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
