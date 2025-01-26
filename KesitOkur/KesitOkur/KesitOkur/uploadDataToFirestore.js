const admin = require("firebase-admin");
const fs = require('fs-extra');
const path = require('path');
const data = require("./kesitokur-app-books.json");

// Firebase Admin SDK'yı başlatıyoruz
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "kesitokur-app.firebasestorage.app" // Replace with your Firebase Storage bucket URL
});

const db = admin.firestore(); // Firestore bağlantısı
const bucket = admin.storage().bucket();

// "books" anahtarına erişiyoruz
const books = data.books;

// Quote image upload function
async function uploadQuoteImages(bookId, quotesDirectoryPath) {
  try {
    // Ensure quotes directory exists and is readable
    await fs.access(quotesDirectoryPath);
    
    const quoteFiles = await fs.readdir(quotesDirectoryPath)
      .then(files => files.filter(file => ['.jpg', '.jpeg', '.png', '.gif'].includes(path.extname(file).toLowerCase())));

    const quoteImageUrls = [];

    // Ensure bucket exists
    try {
      await bucket.exists();
    } catch (bucketError) {
      console.error('Bucket does not exist. Creating bucket...', bucketError);
      try {
        await admin.storage().createBucket('kesitokur-app.appspot.com');
        console.log('Bucket created successfully');
      } catch (createError) {
        console.error('Failed to create bucket:', createError);
        throw createError;
      }
    }

    for (const file of quoteFiles) {
      const filePath = path.join(quotesDirectoryPath, file);
      const destination = `quotes/${bookId}/${file}`;

      try {
        // Upload image to Firebase Storage
        await bucket.upload(filePath, {
          destination: destination,
          metadata: {
            contentType: `image/${path.extname(file).slice(1)}`,
          }
        });

        // Get public URL
        const [url] = await bucket.file(destination).getSignedUrl({
          version: 'v4',
          action: 'read',
          expires: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
        });

        quoteImageUrls.push({
          url: url,
          name: file
        });
      } catch (uploadError) {
        console.error(`Error uploading quote image for book ${bookId}:`, uploadError);
        // Continue with other images even if one fails
      }
    }

    return quoteImageUrls;
  } catch (error) {
    console.error(`Error processing quotes for book ${bookId}:`, error);
    return []; // Return empty array to allow process to continue
  }
}

// Firestore'a verileri yükleme
async function uploadDataToFirestore() {
  try {
    const collectionRef = db.collection("books");

    for (const book of books) {
      // Upload book data
      await collectionRef.doc(book.id).set(book);
      console.log(`Veri yüklendi: ${book.bookName}`);

      // Upload quote images if directory exists
      const quotesDirectoryPath = path.join(__dirname, 'quotes', book.id);
      if (await fs.pathExists(quotesDirectoryPath)) {
        const quoteImageUrls = await uploadQuoteImages(book.id, quotesDirectoryPath);
        // Update Firestore document with quote image URLs
        await db.collection("books").doc(book.id).update({
          quotes: quoteImageUrls
        });
      }
    }

    console.log("Tüm veriler başarıyla yüklendi.");
  } catch (error) {
    console.error("Veri yüklenirken bir hata oluştu:", error);
  } finally {
    process.exit(0);
  }
}

uploadDataToFirestore();
