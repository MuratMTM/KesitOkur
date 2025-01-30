const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
const serviceAccount = require('./backend/firebase/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateBooks() {
  try {
    // Read existing JSON file
    const booksPath = path.join(__dirname, '..', 'KesitOkur', 'KesitOkur', 'kesitokur-app-books.json');
    const booksData = JSON.parse(fs.readFileSync(booksPath, 'utf8'));

    // Batch write to Firestore
    const batch = db.batch();
    const booksCollection = db.collection('books');

    booksData.forEach(book => {
      const bookRef = booksCollection.doc(book.id);
      batch.set(bookRef, {
        bookName: book.bookName,
        authorName: book.authorName,
        publishYear: book.publishYear,
        edition: book.edition,
        pages: book.pages,
        description: book.description,
        bookCover: book.bookCover || '',
        excerpts: book.excerpts || []
      }, { merge: true });
    });

    await batch.commit();
    console.log(`Migrated ${booksData.length} books to Firestore`);
  } catch (error) {
    console.error('Migration error:', error);
  } finally {
    process.exit(0);
  }
}

migrateBooks();
