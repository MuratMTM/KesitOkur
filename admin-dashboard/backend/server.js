const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const { db, bucket } = require('./firebase/admin');
const { syncBooksToJSON } = require('./sync-books');

const app = express();
const upload = multer({ storage: multer.memoryStorage() });

app.use(cors());
app.use(express.json());

app.post('/books/sync', async (req, res) => {
  // Log full request details
  console.log('Sync Route Called - Full Request Details:', {
    method: req.method,
    url: req.url,
    headers: req.headers,
    body: req.body,
    query: req.query,
    params: req.params
  });

  try {
    console.log('Books sync route called');
    const result = await syncBooksToJSON();
    console.log('Sync result:', result);
    res.json({
      message: 'Kitaplar senkronize edildi',
      ...result
    });
  } catch (error) {
    console.error('Senkronizasyon hatası:', {
      message: error.message,
      stack: error.stack,
      code: error.code,
      name: error.name
    });
    res.status(500).json({ 
      error: 'Kitaplar senkronize edilemedi', 
      details: error.message,
      fullError: {
        message: error.message,
        name: error.name,
        code: error.code
      }
    });
  }
});

// Books Routes
app.get('/books', async (req, res) => {
  try {
    const booksSnapshot = await db.collection('books').get();
    const books = booksSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
    res.json(books);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/books', async (req, res) => {
  try {
    const newBook = {
      bookCover: req.body.bookCover || '',
      bookName: req.body.bookName.trim(),
      authorName: req.body.authorName.trim(),
      publishYear: req.body.publishYear,
      edition: req.body.edition,
      pages: req.body.pages,
      description: req.body.description,
      excerpts: req.body.excerpts || [],
      createdAt: new Date().toISOString()
    };
    
    // Check for existing book with same name and author
    const existingBooksQuery = await db.collection('books')
      .where('bookName', '==', newBook.bookName)
      .where('authorName', '==', newBook.authorName)
      .get();
    
    if (!existingBooksQuery.empty) {
      return res.status(400).json({ 
        error: 'Bu kitap zaten mevcut', 
        details: 'Aynı isimde ve yazarla bir kitap zaten var' 
      });
    }
    
    // Add the book to Firestore
    const bookRef = await db.collection('books').add(newBook);
    
    // Construct the response with the Firestore-generated ID
    const bookWithId = {
      id: bookRef.id,
      ...newBook
    };
    
    console.log('New book added:', bookWithId);
    
    // Sync books to JSON
    await syncBooksToJSON();
    
    res.status(201).json(bookWithId);
  } catch (error) {
    console.error('Error adding book:', error);
    res.status(500).json({ 
      error: 'Kitap eklenemedi', 
      details: error.message 
    });
  }
});

app.put('/books/:id', async (req, res) => {
  try {
    const bookId = req.params.id;
    const updatedBook = {
      bookCover: req.body.bookCover || '',
      bookName: req.body.bookName.trim(),
      authorName: req.body.authorName.trim(),
      publishYear: req.body.publishYear,
      edition: req.body.edition,
      pages: req.body.pages,
      description: req.body.description,
      excerpts: req.body.excerpts || []
    };
    
    await db.collection('books').doc(bookId).update(updatedBook);
    
    // Sync books to JSON
    await syncBooksToJSON();
    
    res.json({ id: bookId, ...updatedBook });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/books/:id', async (req, res) => {
  try {
    const bookId = req.params.id;
    
    // Get book data before deletion for logging
    const bookDoc = await db.collection('books').doc(bookId).get();
    const bookData = bookDoc.data();
    
    // Delete the book from Firestore
    await db.collection('books').doc(bookId).delete();
    
    // Sync books to JSON
    await syncBooksToJSON();
    
    res.status(200).json({ 
      message: 'Kitap listeden silindi', 
      bookId, 
      bookName: bookData.bookName 
    });
  } catch (error) {
    console.error('Detaylı silme hatası:', {
      message: error.message,
      stack: error.stack,
      code: error.code
    });
    
    res.status(500).json({ 
      error: 'Kitap silinemedi', 
      details: error.message 
    });
  }
});

app.post('/books/:bookId/quotes', upload.single('quote'), async (req, res) => {
  try {
    const bookId = req.params.bookId;
    const file = req.file;

    if (!file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const filename = `book_quotes/${bookId}/${Date.now()}_${file.originalname}`;
    const fileUpload = bucket.file(filename);

    const blobStream = fileUpload.createWriteStream({
      metadata: {
        contentType: file.mimetype
      }
    });

    blobStream.on('error', (err) => {
      res.status(500).json({ error: err.message });
    });

    blobStream.on('finish', async () => {
      await fileUpload.makePublic();
      const publicUrl = fileUpload.publicUrl();

      await db.collection('books').doc(bookId).update({
        excerpts: db.FieldValue.arrayUnion(publicUrl)
      });

      res.json({ url: publicUrl });
    });

    blobStream.end(file.buffer);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/books/:bookId/quotes', upload.single('quote'), async (req, res) => {
  try {
    const bookId = req.params.bookId;
    
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }
    
    const filename = `quotes/${bookId}/${Date.now()}_${req.file.originalname}`;
    const fileRef = bucket.file(filename);
    
    const stream = fileRef.createWriteStream({
      metadata: {
        contentType: req.file.mimetype
      }
    });
    
    stream.on('error', (err) => {
      console.error(err);
      res.status(500).json({ error: 'Upload failed' });
    });
    
    stream.on('finish', async () => {
      await fileRef.makePublic();
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filename}`;
      
      const bookDoc = await db.collection('books').doc(bookId).get();
      const bookData = bookDoc.data();
      const updatedExcerpts = [...(bookData.excerpts || []), publicUrl];
      
      await db.collection('books').doc(bookId).update({
        excerpts: updatedExcerpts
      });
      
      res.json({ 
        message: 'Quote uploaded successfully', 
        quoteUrl: publicUrl 
      });
    });
    
    stream.end(req.file.buffer);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.delete('/books/:bookId/quotes', async (req, res) => {
  try {
    const bookId = req.params.bookId;
    const quoteUrl = req.body.quoteUrl;
    
    const filename = quoteUrl.replace('https://storage.googleapis.com/kesitokur-app.appspot.com/', '');
    const fileRef = bucket.file(filename);
    
    try {
      await fileRef.delete();
    } catch (storageError) {
      console.log(`Could not delete quote: ${quoteUrl}`, storageError);
    }
    
    const bookDoc = await db.collection('books').doc(bookId).get();
    const bookData = bookDoc.data();
    const updatedExcerpts = (bookData.excerpts || []).filter(url => url !== quoteUrl);
    
    await db.collection('books').doc(bookId).update({
      excerpts: updatedExcerpts
    });
    
    res.json({ message: 'Quote deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/books/remove-duplicates', async (req, res) => {
  try {
    // Fetch all books
    const booksSnapshot = await db.collection('books').get();
    const books = booksSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    // Group books by name and author
    const bookGroups = {};
    books.forEach(book => {
      const key = `${book.bookName.trim().toLowerCase()}_${book.authorName.trim().toLowerCase()}`;
      if (!bookGroups[key]) {
        bookGroups[key] = [];
      }
      bookGroups[key].push(book);
    });

    // Find and remove duplicates
    const duplicatesToRemove = [];
    Object.values(bookGroups).forEach(group => {
      // If more than one book with same name and author
      if (group.length > 1) {
        // Keep the first book, remove the rest
        const [first, ...rest] = group;
        duplicatesToRemove.push(...rest);
      }
    });

    // Remove duplicate books
    const deletePromises = duplicatesToRemove.map(async (book) => {
      console.log(`Removing duplicate book: ${book.bookName} (ID: ${book.id})`);
      
      // Remove associated excerpts from Storage
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
    });

    await Promise.all(deletePromises);

    res.json({
      message: `${duplicatesToRemove.length} duplicate books removed`,
      removedBooks: duplicatesToRemove.map(book => ({
        id: book.id,
        bookName: book.bookName,
        authorName: book.authorName
      }))
    });
  } catch (error) {
    console.error('Error removing duplicate books:', error);
    res.status(500).json({ 
      error: 'Duplicate kitaplar silinemedi', 
      details: error.message 
    });
  }
});

// Debug route to list all book IDs
app.get('/books/list-ids', async (req, res) => {
  try {
    const booksSnapshot = await db.collection('books').get();
    const bookIds = booksSnapshot.docs.map(doc => ({
      id: doc.id,
      bookName: doc.data().bookName,
      authorName: doc.data().authorName
    }));
    
    console.log('Current book IDs:', bookIds);
    
    res.json({
      totalBooks: bookIds.length,
      books: bookIds
    });
  } catch (error) {
    console.error('Error listing book IDs:', error);
    res.status(500).json({ 
      error: 'Kitap kimlikleri listelenemedi', 
      details: error.message 
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
