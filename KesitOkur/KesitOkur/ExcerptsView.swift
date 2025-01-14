//
//  ExcerptsView.swift
//  KesitOkur
//
//  Created by Murat Işık on 14.01.2025.
//

import SwiftUI

struct ExcerptsView: View {
    let book: Book
    @Environment(\.dismiss) var dismiss
    @State private var currentIndex = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Excerpts Gallery
            TabView(selection: $currentIndex) {
                ForEach(Array(book.excerpts.enumerated()), id: \.element) { index, excerptURL in
                    AsyncImage(url: URL(string: excerptURL)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    } placeholder: {
                        ProgressView()
                            .foregroundColor(.white)
                    }
                    .padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            
            // Close Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Page indicator
                    Text("\(currentIndex + 1) / \(book.excerpts.count)")
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer()
            }
        }
    }
}
#Preview {
    ExcerptsView()
}
