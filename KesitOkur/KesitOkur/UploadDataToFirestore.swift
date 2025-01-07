//
//  UploadDataToFirestore.swift
//  KesitOkur
//
//  Created by Murat Işık on 6.01.2025.
//

import Foundation
import FirebaseFirestore

// JSON dosyasını okuma
func loadJSONFromFile() -> [String: Any]? {
    if let url = Bundle.main.url(forResource: "data", withExtension: "json") {
        do {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                return json
            }
        } catch {
            print("JSON dosyası yüklenirken hata: \(error.localizedDescription)")
        }
    }
    return nil
}

// Firestore'a veri yükleme
func uploadDataToFirestore() {
    let db = Firestore.firestore()
    if let jsonData = loadJSONFromFile() {
        if let books = jsonData["kesitokur-app-books"] as? [String: [String: Any]] {
            for (key, value) in books {
                db.collection("kesitokur-app-books").document(key).setData(value) { error in
                    if let error = error {
                        print("Hata oluştu: \(error.localizedDescription)")
                    } else {
                        print("\(key) başarıyla yüklendi!")
                    }
                }
            }
        }
    }
}



