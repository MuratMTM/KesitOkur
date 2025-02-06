const admin = require("firebase-admin");
const fs = require('fs-extra');
const path = require('path');

// Firebase Admin SDK initialization
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "kesitokur-app.firebasestorage.app"
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

// Book configurations
const books = [
  /* {
    id: "31",
    sourcePath: "/Users/muratisik/Desktop/KesitOkurr/Sapiens",
    name: "Sapiens"
  },
  {
    id: "32",
    sourcePath: "/Users/muratisik/Desktop/KesitOkurr/Steve Jobs",
    name: "Steve Jobs"
  }, */
  {
    id: "6",
    sourcePath: "/Users/muratisik/Desktop/KesitOkurr/Irade Terbiyesi",
    name: "Irade Terbiyesi"
  }
];

// Upload quote images for a book
async function uploadQuoteImages(book) {
  try {
    const files = await fs.readdir(book.sourcePath);
    const imageFiles = files.filter(file => 
      ['.jpg', '.jpeg', '.png'].includes(path.extname(file).toLowerCase()) &&
      !file.startsWith('.')  // Exclude hidden files like .DS_Store
    );

    const quoteUrls = [];
    console.log(`Processing ${imageFiles.length} quotes for ${book.name}...`);

    for (const file of imageFiles) {
      const filePath = path.join(book.sourcePath, file);
      const destination = `quotes/${book.id}/${file}`;

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

        console.log(`✓ Uploaded: ${file}`);
        quoteUrls.push(url);
      } catch (uploadError) {
        console.error(`Error uploading quote image:`, uploadError);
      }
    }

    if (quoteUrls.length > 0) {
      // Update Firestore with quote URLs
      await db.collection("books").doc(book.id).update({
        excerpts: admin.firestore.FieldValue.arrayUnion(...quoteUrls),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      console.log(`✓ Successfully uploaded ${quoteUrls.length} quotes for "${book.name}"`);
      console.log(`Total quotes for book: ${quoteUrls.length}`);
    }
  } catch (error) {
    console.error(`Error processing quotes for book ${book.name}:`, error);
  }
}

// Main function to upload quotes
async function uploadQuotes() {
  for (const book of books) {
    console.log(`\nProcessing book: ${book.name} (ID: ${book.id})`);
    
    try {
      // Upload and process quotes
      await uploadQuoteImages(book);
    } catch (error) {
      console.error(`Error processing book ${book.name}:`, error);
    }
  }
}

// Run the upload process
console.log('Starting quote upload process...');
uploadQuotes()
  .then(() => {
    console.log('\nUpload process completed successfully!');
    process.exit(0);
  })
  .catch(error => {
    console.error('Error in upload process:', error);
    process.exit(1);
  });
