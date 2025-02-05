const admin = require("firebase-admin");
const fs = require('fs-extra');
const path = require('path');
const data = require("./kesitokur-app-books.json");

// Configuration
const SOURCE_DIR = '/Users/muratisik/Desktop/KesitOkurr';
const QUOTES_DIR = path.join(__dirname, 'quotes');

// Firebase Admin SDK initialization
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "kesitokur-app.firebasestorage.app"
});

const db = admin.firestore();
const bucket = admin.storage().bucket();
const books = data.books;

// Prepare quotes by copying them from source to destination
async function prepareQuotes(bookId, bookName) {
  const sourcePath = path.join(SOURCE_DIR, bookName);
  const destPath = path.join(QUOTES_DIR, bookId);

  try {
    // Check if source directory exists
    if (!await fs.pathExists(sourcePath)) {
      console.log(`Skipping ${bookName}: Source directory not found`);
      return;
    }

    // Create destination directory
    await fs.ensureDir(destPath);
    
    // Copy images
    await fs.copy(sourcePath, destPath, {
      filter: (src) => {
        const ext = path.extname(src).toLowerCase();
        return ['.jpg', '.jpeg', '.png', '.gif'].includes(ext);
      },
      overwrite: false // Don't overwrite existing files
    });
    
    console.log(`✓ Prepared quotes for: ${bookName}`);
  } catch (error) {
    console.error(`Error preparing quotes for ${bookName}:`, error);
  }
}

// Upload quote images for a book
async function uploadQuoteImages(bookId, quotesDirectoryPath) {
  try {
    // Ensure quotes directory exists and is readable
    await fs.access(quotesDirectoryPath);
    
    const quoteFiles = await fs.readdir(quotesDirectoryPath)
      .then(files => files.filter(file => 
        ['.jpg', '.jpeg', '.png', '.gif'].includes(path.extname(file).toLowerCase()) &&
        !file.startsWith('.')
      ));

    const quoteImageUrls = [];
    console.log(`Processing ${quoteFiles.length} quotes...`);

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
          expires: Date.now() + 365 * 24 * 60 * 60 * 1000, // 1 year
        });

        quoteImageUrls.push({
          url: url,
          name: file,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log(`✓ Uploaded: ${file}`);
      } catch (uploadError) {
        console.error(`Error uploading quote image:`, uploadError);
      }
    }

    return quoteImageUrls;
  } catch (error) {
    console.error(`Error processing quotes for book ${bookId}:`, error);
    return [];
  }
}

// Main function to process all books
async function processBooks() {
  try {
    console.log('Step 1: Preparing quotes directories...');
    for (const book of books) {
      await prepareQuotes(book.id, book.bookName);
    }

    console.log('\nStep 2: Uploading books and quotes to Firebase...');
    const collectionRef = db.collection("books");

    for (const book of books) {
      // Upload book data
      await collectionRef.doc(book.id).set(book);
      console.log(`✓ Uploaded book data: ${book.bookName}`);

      // Upload quote images if directory exists
      const quotesDirectoryPath = path.join(QUOTES_DIR, book.id);
      if (await fs.pathExists(quotesDirectoryPath)) {
        const quoteImageUrls = await uploadQuoteImages(book.id, quotesDirectoryPath);
        
        if (quoteImageUrls.length > 0) {
          // Update Firestore document with quote image URLs
          await db.collection("books").doc(book.id).update({
            quotes: admin.firestore.FieldValue.arrayUnion(...quoteImageUrls),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
          console.log(`✓ Updated ${quoteImageUrls.length} quotes for: ${book.bookName}`);
        }
      }
    }

    console.log('\n✓ All books and quotes processed successfully!');
  } catch (error) {
    console.error('Error processing books:', error);
  }
}

// Run the process
console.log('Starting book processing...');
processBooks()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
