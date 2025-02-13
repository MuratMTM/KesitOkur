const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin SDK
const serviceAccount = require('./backend/firebase/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const bucket = admin.storage().bucket('gs://kesitokur-app.firebasestorage.app');

async function fetchExistingQuotes() {
  try {
    // Fetch all books
    const booksSnapshot = await db.collection('books').get();
    const books = booksSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    console.log(`Found ${books.length} books`);

    // Prepare to store quotes for each book
    const booksWithQuotes = [];

    // List ALL files in the quotes directory
    const [files] = await bucket.getFiles({ prefix: 'quotes/' });
    console.log(`Total files in quotes directory: ${files.length}`);

    // Iterate through each book
    for (const book of books) {
      // Find quotes for this book
      const bookQuotes = files.filter(file => 
        // Check if the file is in a directory matching the book's ID
        file.name.startsWith(`quotes/${book.id}/`) && 
        // Ensure it's an image file
        (file.name.toLowerCase().endsWith('.jpg') || 
         file.name.toLowerCase().endsWith('.png') || 
         file.name.toLowerCase().endsWith('.jpeg'))
      );

      console.log(`Found ${bookQuotes.length} quote files for book: ${book.bookName}`);

      // Use a Set to track unique quote filenames
      const uniqueQuoteFilenames = new Set();
      const quotes = [];

      // Process each quote file
      for (const file of bookQuotes) {
        // Use the base filename (without path and extension) as the unique key
        const baseFilename = path.basename(file.name, path.extname(file.name));
        
        if (!uniqueQuoteFilenames.has(baseFilename)) {
          const publicUrl = `https://firebasestorage.googleapis.com/v0/b/kesitokur-app.appspot.com/o/${encodeURIComponent(file.name)}?alt=media`;
          
          const [metadata] = await file.getMetadata();
          
          quotes.push({
            url: publicUrl,
            name: file.name,
            size: metadata.size,
            contentType: metadata.contentType,
            timeCreated: metadata.timeCreated
          });

          uniqueQuoteFilenames.add(baseFilename);
        }
      }

      console.log(`Unique quotes for ${book.bookName}: ${quotes.length}`);

      // Add quotes to the book object
      if (quotes.length > 0) {
        const quoteUrls = quotes.map(quote => quote.url);
        
        // Update the book's excerpts in Firestore, ensuring the field exists
        await db.collection('books').doc(book.id).update({
          excerpts: admin.firestore.FieldValue.arrayUnion(...quoteUrls)
        });
        
        console.log(`Updated ${book.bookName} with ${quoteUrls.length} excerpts`);

        booksWithQuotes.push({
          ...book,
          quotes: quotes
        });
      }
    }

    // Write results to a JSON file for easy inspection
    fs.writeFileSync(
      path.join(__dirname, 'existing_quotes.json'), 
      JSON.stringify(booksWithQuotes, null, 2)
    );

    console.log('Existing quotes have been fetched and saved to existing_quotes.json');
    console.log(`Total books with quotes: ${booksWithQuotes.length}`);

    return booksWithQuotes;
  } catch (error) {
    console.error('Detailed error during quote fetching:', {
      message: error.message,
      code: error.code,
      stack: error.stack
    });
    throw error;
  } finally {
    // Properly close the Firebase app
    admin.app().delete();
  }
}

// Run the quote fetching
fetchExistingQuotes()
  .then(books => {
    console.log('Quote fetching completed successfully');
    process.exit(0);
  })
  .catch(error => {
    console.error('Failed to fetch quotes:', error);
    process.exit(1);
  });
