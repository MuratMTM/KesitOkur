const admin = require("firebase-admin");
const data = require("./kesitokur-app-books.json");

// Firebase Admin SDK'yı başlatıyoruz
const serviceAccount = require("./serviceAccountKey.json"); // Service Account JSON dosyanızın adı

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore(); // Firestore bağlantısı

// "books" anahtarına erişiyoruz
const books = data.books;

// Firestore'a verileri yükleme
async function uploadDataToFirestore() {
  try {
    const collectionRef = db.collection("books");

    books.forEach(async (book) => {
      await collectionRef.doc(book.id).set(book);
      console.log(`Veri yüklendi: ${book.bookName}`);
    });

    console.log("Tüm veriler başarıyla yüklendi.");
  } catch (error) {
    console.error("Veri yüklenirken bir hata oluştu:", error);
  }
}

uploadDataToFirestore();
