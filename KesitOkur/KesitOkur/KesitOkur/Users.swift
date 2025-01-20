//
//  Users.swift
//  KesitOkur
//
//  Created by Murat Işık on 15.01.2025.
//

import Foundation

struct UserProfile: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let isAdmin: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case email
        case isAdmin
        case createdAt
    }
}
