const fs = require('fs');
const path = require('path');
const { db } = require('./firebase/admin');
const { Storage } = require('@google-cloud/storage');
const bucket = new Storage().bucket('kesitokur-app.appspot.com');

// Function to find the JSON file
function findJSONFile() {
  const possiblePaths = [
    path.resolve(__dirname, '../../KesitOkur/KesitOkur/KesitOkur/KesitOkur/kesitokur-app-books.json'),
    path.resolve(__dirname, '../../../KesitOkur/KesitOkur/KesitOkur/KesitOkur/kesitokur-app-books.json'),
    path.resolve(process.cwd(), 'kesitokur-app-books.json'),
    path.resolve(process.env.HOME, 'Desktop/KesitOkur(App)/KesitOkur/KesitOkur/KesitOkur/KesitOkur/kesitokur-app-books.json')
  ];

  for (const filePath of possiblePaths) {
    console.log(`Checking JSON file path: ${filePath}`);
    if (fs.existsSync(filePath)) {
      console.log(`JSON file found at: ${filePath}`);
      return filePath;
    }
  }

  console.error('JSON file not found in any of the expected locations');
  throw new Error('kesitokur-app-books.json file not found');
}

async function syncBooksToJSON() {
  try {
    // Find the JSON file path
    const jsonFilePath = findJSONFile();
    
    console.log(`Using JSON file path: ${jsonFilePath}`);

    // Read existing JSON file
    let existingBooks = [];
    try {
      const fileContents = fs.readFileSync(jsonFilePath, 'utf8').trim();
      
      console.log('Raw File Contents:', fileContents);
      
      // Check if file is empty or not valid JSON
      if (!fileContents) {
        console.warn('JSON file is empty');
        return { totalBooks: 0, updatedBooks: [], removedBooks: [] };
      }
      
      // Try parsing the JSON, with multiple fallback strategies
      let parsedData;
      try {
        parsedData = JSON.parse(fileContents);
      } catch (jsonError) {
        console.warn('JSON parsing failed, attempting alternative parsing');
        
        // Try removing potential BOM or extra whitespace
        const cleanedContents = fileContents.replace(/^\uFEFF/, '').trim();
        parsedData = JSON.parse(cleanedContents);
      }

      // Handle nested books structure
      existingBooks = parsedData.books || parsedData;

      // Ensure existingBooks is an array
      if (!Array.isArray(existingBooks)) {
        console.warn('Parsed content is not an array, converting to array');
        existingBooks = [existingBooks];
      }
      
      console.log('Parsed Books:', existingBooks);
      
      // Validate books have required fields and are objects
      existingBooks = existingBooks.filter(book => {
        // Ensure book is an object
        if (typeof book !== 'object' || book === null) {
          console.warn('Invalid book (not an object):', book);
          return false;
        }

        // Check for required fields
        const isValid = book.bookName && book.authorName;
        if (!isValid) {
          console.warn('Invalid book (missing required fields):', book);
        }
        return isValid;
      });

      console.log('Validated Books:', existingBooks);
    } catch (readError) {
      console.error('Error reading or parsing JSON file:', {
        message: readError.message,
        stack: readError.stack,
        code: readError.code,
        fileContents: fileContents
      });
      throw readError;
    }

    // Fetch books from Firestore
    const booksSnapshot = await db.collection('books').get();
    const firestoreBooks = booksSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    console.log('Current Firestore Books:', firestoreBooks);

    // Books to add to Firestore
    const booksToAdd = [];
    
    // Books to remove from Firestore
    const booksToRemove = [];

    // Create a map of existing books from JSON
    const existingBooksMap = new Map(
      existingBooks.map(book => [`${book.bookName}_${book.authorName}`, book])
    );

    // Create a map of Firestore books
    const firestoreBooksMap = new Map(
      firestoreBooks.map(book => [`${book.bookName}_${book.authorName}`, book])
    );

    // Check JSON books against Firestore
    for (const book of existingBooks) {
      const key = `${book.bookName}_${book.authorName}`;
      
      // If book doesn't exist in Firestore, add it
      if (!firestoreBooksMap.has(key)) {
        booksToAdd.push(book);
      }
    }

    console.log('Books to Add:', booksToAdd);

    // Check Firestore books against JSON books
    for (const book of firestoreBooks) {
      const key = `${book.bookName}_${book.authorName}`;
      
      // If book doesn't exist in JSON, mark for removal
      if (!existingBooksMap.has(key)) {
        booksToRemove.push(book);
      }
    }

    console.log('Books to Remove:', booksToRemove);

    // Add new books to Firestore
    const addPromises = booksToAdd.map(async (book) => {
      console.log(`Adding new book to Firestore: ${book.bookName}`);
      try {
        const newBookRef = await db.collection('books').add({
          bookName: book.bookName,
          authorName: book.authorName,
          bookCover: book.bookCover || '',
          publishYear: book.publishYear,
          edition: book.edition,
          pages: book.pages,
          description: book.description,
          excerpts: book.excerpts || [],
          createdAt: new Date().toISOString()
        });
        console.log(`Book added successfully: ${book.bookName}, ID: ${newBookRef.id}`);
      } catch (addError) {
        console.error(`Error adding book ${book.bookName}:`, {
          message: addError.message,
          stack: addError.stack
        });
        throw addError;
      }
    });

    // Remove books not in JSON from Firestore
    const removePromises = booksToRemove.map(async (book) => {
      console.log(`Removing book not in JSON: ${book.bookName}`);
      
      try {
        // Remove associated excerpts from Storage if exists
        if (book.excerpts && book.excerpts.length > 0) {
          const excerptDeletePromises = book.excerpts.map(async (excerptUrl) => {
            try {
              const filename = excerptUrl.replace('https://storage.googleapis.com/kesitokur-app.appspot.com/', '');
              const fileRef = bucket.file(filename);
              await fileRef.delete();
            } catch (storageError) {
              console.error(`Could not delete excerpt: ${excerptUrl}`, storageError);
            }
          });
          await Promise.all(excerptDeletePromises);
        }
        
        // Delete book from Firestore
        await db.collection('books').doc(book.id).delete();
        console.log(`Book removed successfully: ${book.bookName}`);
      } catch (removeError) {
        console.error(`Error removing book ${book.bookName}:`, {
          message: removeError.message,
          stack: removeError.stack
        });
        throw removeError;
      }
    });

    // Wait for all operations to complete
    await Promise.all([...addPromises, ...removePromises]);

    console.log('Book synchronization completed successfully');

    return {
      totalBooks: existingBooks.length,
      addedBooks: booksToAdd.map(book => ({
        bookName: book.bookName,
        authorName: book.authorName
      })),
      removedBooks: booksToRemove.map(book => ({
        id: book.id,
        bookName: book.bookName,
        authorName: book.authorName
      }))
    };
  } catch (error) {
    console.error('Error synchronizing books:', {
      message: error.message,
      stack: error.stack,
      code: error.code
    });
    throw error;
  }
}

// If called directly, run the sync
if (require.main === module) {
  syncBooksToJSON()
    .then(result => {
      console.log('Book sync completed');
      console.log(`Added ${result.addedBooks.length} books`);
      console.log(`Removed ${result.removedBooks.length} books`);
    })
    .catch(error => console.error('Book sync failed:', error));
}

module.exports = { syncBooksToJSON };
