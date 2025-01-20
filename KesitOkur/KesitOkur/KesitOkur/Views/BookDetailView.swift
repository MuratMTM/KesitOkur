struct BookDetailView: View {
    let book: Book
    @State private var showExcerpts = false
    @EnvironmentObject var favoritesManager: FavoritesManager
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1, green: 0.85, blue: 0.4),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .center, spacing: 12) {
                    // Existing book cover and details...
                    
                    // Add Excerpts Button
                    Button(action: {
                        showExcerpts = true
                    }) {
                        HStack {
                            Image(systemName: "text.quote")
                            Text("Alıntılar")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showExcerpts) {
            ExcerptsView(book: book)
        }
    }
} 