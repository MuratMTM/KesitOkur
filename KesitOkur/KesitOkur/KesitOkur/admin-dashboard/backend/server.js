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
    const booksRef = db.collection('books');
    const snapshot = await booksRef.get();

    const books = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));

    res.json({ 
      books,
      totalBooks: books.length
    });
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
  console.log('Quote upload request received');
  console.log('Request details:', {
    bookId: req.params.bookId,
    files: req.file ? {
      fieldname: req.file.fieldname,
      originalname: req.file.originalname,
      encoding: req.file.encoding,
      mimetype: req.file.mimetype,
      size: req.file.size
    } : 'No file',
    body: req.body
  });

  try {
    const bookId = req.params.bookId;
    const file = req.file;
    const tags = req.body.tags ? req.body.tags.split(',').map(tag => tag.trim()) : [];

    if (!file) {
      console.error('No file uploaded');
      return res.status(400).json({ 
        error: 'No file uploaded', 
        details: 'Please select a file to upload' 
      });
    }

    // Validate file type (optional)
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
    if (!allowedTypes.includes(file.mimetype)) {
      console.error(`Invalid file type: ${file.mimetype}`);
      return res.status(400).json({ 
        error: 'Invalid file type', 
        details: 'Only JPEG, PNG, and GIF images are allowed' 
      });
    }

    // Validate file size (optional, e.g., max 5MB)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      console.error(`File too large: ${file.size} bytes`);
      return res.status(400).json({ 
        error: 'File too large', 
        details: 'Maximum file size is 5MB' 
      });
    }

    // Generate a unique filename
    const filename = `quotes/${bookId}/${Date.now()}_${file.originalname}`;
    const fileUpload = bucket.file(filename);

    // Create a write stream
    const blobStream = fileUpload.createWriteStream({
      metadata: {
        contentType: file.mimetype
      }
    });

    blobStream.on('error', (err) => {
      console.error('File upload to storage error:', err);
      res.status(500).json({ 
        error: 'File upload failed', 
        details: err.message 
      });
    });

    blobStream.on('finish', async () => {
      try {
        // Make the file publicly accessible
        await fileUpload.makePublic();

        // Construct the public URL
        const publicUrl = `https://storage.googleapis.com/${bucket.name}/${filename}`;
        console.log(`Generated public URL: ${publicUrl}`);

        // Fetch the current book document
        const bookDoc = await db.collection('books').doc(bookId).get();
        const bookData = bookDoc.data();

        console.log(`Book data before update: ${JSON.stringify(bookData)}`);

        // Ensure excerpts array exists
        const currentExcerpts = bookData.excerpts || [];

        // Add the new quote URL to excerpts
        const updatedExcerpts = [...currentExcerpts, publicUrl];

        // Update the book document with the new excerpts
        await db.collection('books').doc(bookId).update({
          excerpts: updatedExcerpts
        });

        console.log(`Updated excerpts for book ${bookId}: ${JSON.stringify(updatedExcerpts)}`);

        // Respond with success and the new quote URL
        res.status(201).json({ 
          message: 'Quote uploaded successfully', 
          quoteUrl: publicUrl,
          totalQuotes: updatedExcerpts.length
        });
      } catch (updateError) {
        console.error('Error updating book document:', updateError);
        res.status(500).json({ 
          error: 'Failed to update book quotes', 
          details: updateError.message 
        });
      }
    });

    // Write the file
    blobStream.end(file.buffer);
  } catch (error) {
    console.error('Unexpected quote upload error:', error);
    res.status(500).json({ 
      error: 'Unexpected error during quote upload', 
      details: error.message 
    });
  }
});

app.put('/books/:bookId/quotes/:quoteIndex/tags', async (req, res) => {
  try {
    const { bookId, quoteIndex } = req.params;
    const { tags } = req.body;
    
    if (!Array.isArray(tags)) {
      return res.status(400).json({ error: 'Tags must be an array' });
    }
    
    const bookDoc = await db.collection('books').doc(bookId).get();
    const bookData = bookDoc.data();
    
    if (!bookData.quotes || bookData.quotes.length <= quoteIndex) {
      return res.status(404).json({ error: 'Quote not found' });
    }
    
    // Update tags for specific quote
    bookData.quotes[quoteIndex].tags = tags;
    
    await db.collection('books').doc(bookId).update({
      quotes: bookData.quotes
    });
    
    res.json({ 
      message: 'Quote tags updated successfully',
      quote: bookData.quotes[quoteIndex]
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/books/quotes/tags', async (req, res) => {
  try {
    const booksSnapshot = await db.collection('books').get();
    const allTags = new Set();
    
    booksSnapshot.docs.forEach(doc => {
      const bookData = doc.data();
      if (bookData.quotes) {
        bookData.quotes.forEach(quote => {
          if (quote.tags) {
            quote.tags.forEach(tag => allTags.add(tag));
          }
        });
      }
    });
    
    res.json({ tags: Array.from(allTags) });
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
    const updatedQuotes = (bookData.quotes || []).filter(quote => quote.url !== quoteUrl);
    
    await db.collection('books').doc(bookId).update({
      quotes: updatedQuotes
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

// Mobile App Routes for Quote Tag Management
app.post('/mobile/books/:bookId/quotes/:quoteIndex/tags', async (req, res) => {
  try {
    const { bookId, quoteIndex } = req.params;
    const { tags } = req.body;
    
    if (!Array.isArray(tags)) {
      return res.status(400).json({ error: 'Tags must be an array of strings' });
    }
    
    // Validate tags (optional: add more strict validation if needed)
    const sanitizedTags = tags
      .map(tag => tag.trim())
      .filter(tag => tag.length > 0)
      .slice(0, 10); // Limit to 10 tags
    
    const bookDoc = await db.collection('books').doc(bookId).get();
    const bookData = bookDoc.data();
    
    if (!bookData.quotes || bookData.quotes.length <= quoteIndex) {
      return res.status(404).json({ error: 'Quote not found' });
    }
    
    // Update tags for specific quote
    bookData.quotes[quoteIndex].tags = sanitizedTags;
    
    await db.collection('books').doc(bookId).update({
      quotes: bookData.quotes
    });
    
    res.json({ 
      message: 'Quote tags updated successfully',
      quote: bookData.quotes[quoteIndex]
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/mobile/books/quotes/filter', async (req, res) => {
  try {
    const { tags } = req.query;
    const tagArray = tags ? tags.split(',').map(tag => tag.trim()) : [];
    
    const booksSnapshot = await db.collection('books').get();
    const filteredBooks = [];
    
    booksSnapshot.docs.forEach(doc => {
      const bookData = doc.data();
      if (bookData.quotes) {
        const matchingQuotes = bookData.quotes.filter(quote => 
          tagArray.length === 0 || 
          tagArray.some(tag => quote.tags && quote.tags.includes(tag))
        );
        
        if (matchingQuotes.length > 0) {
          filteredBooks.push({
            id: doc.id,
            bookName: bookData.bookName,
            authorName: bookData.authorName,
            quotes: matchingQuotes
          });
        }
      }
    });
    
    res.json({
      books: filteredBooks,
      totalMatchingQuotes: filteredBooks.reduce((total, book) => total + book.quotes.length, 0)
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/mobile/books/:bookId/quotes/tags', async (req, res) => {
  try {
    const { bookId } = req.params;
    
    const bookDoc = await db.collection('books').doc(bookId).get();
    const bookData = bookDoc.data();
    
    if (!bookData || !bookData.quotes) {
      return res.json({ tags: [] });
    }
    
    // Collect unique tags from book quotes
    const allTags = new Set();
    bookData.quotes.forEach(quote => {
      if (quote.tags) {
        quote.tags.forEach(tag => allTags.add(tag));
      }
    });
    
    res.json({ 
      tags: Array.from(allTags),
      totalQuotes: bookData.quotes.length
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Route to retrieve all quotes for a book
app.get('/books/:bookId/quotes', async (req, res) => {
  try {
    const { bookId } = req.params;
    const { 
      sortBy = 'uploadedAt', 
      sortOrder = 'desc', 
      limit = 100 
    } = req.query;

    const bookDoc = await db.collection('books').doc(bookId).get();
    const bookData = bookDoc.data();

    if (!bookData || !bookData.quotes) {
      return res.json({ 
        quotes: [], 
        totalQuotes: 0,
        bookName: bookData?.bookName || 'Unknown Book'
      });
    }

    // Sort quotes
    const sortedQuotes = [...bookData.quotes].sort((a, b) => {
      const valueA = a[sortBy] || '';
      const valueB = b[sortBy] || '';
      return sortOrder === 'desc' 
        ? valueB.localeCompare(valueA) 
        : valueA.localeCompare(valueB);
    });

    // Apply limit
    const limitedQuotes = sortedQuotes.slice(0, Number(limit));

    res.json({
      quotes: limitedQuotes,
      totalQuotes: bookData.quotes.length,
      bookName: bookData.bookName
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Route to update a specific quote
app.put('/books/:bookId/quotes/:quoteIndex', async (req, res) => {
  try {
    const { bookId, quoteIndex } = req.params;
    const updateData = req.body;

    // Validate input
    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ error: 'No update data provided' });
    }

    const bookDoc = await db.collection('books').doc(bookId).get();
    const bookData = bookDoc.data();

    if (!bookData.quotes || bookData.quotes.length <= quoteIndex) {
      return res.status(404).json({ error: 'Quote not found' });
    }

    // Allowed fields to update
    const allowedUpdates = ['tags'];
    const validUpdates = {};

    allowedUpdates.forEach(field => {
      if (updateData[field] !== undefined) {
        validUpdates[field] = updateData[field];
      }
    });

    // Update specific quote
    bookData.quotes[quoteIndex] = {
      ...bookData.quotes[quoteIndex],
      ...validUpdates
    };

    await db.collection('books').doc(bookId).update({
      quotes: bookData.quotes
    });

    res.json({ 
      message: 'Quote updated successfully',
      quote: bookData.quotes[quoteIndex]
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Route to delete a specific quote
app.delete('/books/:bookId/quotes/:quoteIndex', async (req, res) => {
  try {
    const { bookId, quoteIndex } = req.params;

    const bookDoc = await db.collection('books').doc(bookId).get();
    const bookData = bookDoc.data();

    if (!bookData.quotes || bookData.quotes.length <= quoteIndex) {
      return res.status(404).json({ error: 'Quote not found' });
    }

    // Get the quote to be deleted (for potential file deletion)
    const quoteToDelete = bookData.quotes[quoteIndex];

    // Remove quote from array
    const updatedQuotes = bookData.quotes.filter((_, index) => index !== Number(quoteIndex));

    // If quote has an image URL, attempt to delete from storage
    if (quoteToDelete.url) {
      try {
        const filename = quoteToDelete.url.replace('https://storage.googleapis.com/kesitokur-app.appspot.com/', '');
        const fileRef = bucket.file(filename);
        await fileRef.delete();
      } catch (storageError) {
        console.log(`Could not delete quote image: ${quoteToDelete.url}`, storageError);
      }
    }

    // Update book document
    await db.collection('books').doc(bookId).update({
      quotes: updatedQuotes
    });

    res.json({ 
      message: 'Quote deleted successfully',
      remainingQuotes: updatedQuotes.length
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Route to search for a book by name
app.get('/books/search', async (req, res) => {
  try {
    const { name, exact = false } = req.query;
    
    if (!name) {
      return res.status(400).json({ error: 'Book name is required' });
    }

    const booksRef = db.collection('books');
    const snapshot = await booksRef.get();

    // Matching strategy based on 'exact' parameter
    const matchedBooks = snapshot.docs.filter(doc => {
      const bookName = doc.data().bookName;
      return exact 
        ? bookName === name 
        : bookName.toLowerCase().includes(name.toLowerCase());
    });

    if (matchedBooks.length === 0) {
      return res.status(404).json({ error: 'Book not found' });
    }

    const bookDoc = matchedBooks[0];
    res.json({
      bookId: bookDoc.id,
      bookName: bookDoc.data().bookName
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
