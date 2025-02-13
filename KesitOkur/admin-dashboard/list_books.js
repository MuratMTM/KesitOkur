const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('./backend/firebase/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function listBooks() {
    try {
        const booksRef = db.collection('books');
        const snapshot = await booksRef.get();

        const books = snapshot.docs.map(doc => ({
            id: doc.id,
            ...doc.data()
        }));

        console.log('Total Books:', books.length);
        books.forEach(book => {
            console.log('Book:', {
                id: book.id,
                name: book.bookName,
                excerpts: book.excerpts || 'No excerpts',
                excerptCount: book.excerpts ? book.excerpts.length : 0
            });
        });
    } catch (error) {
        console.error('Error listing books:', error);
    }
}

listBooks();
