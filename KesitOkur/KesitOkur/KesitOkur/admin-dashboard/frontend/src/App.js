import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [books, setBooks] = useState([]);
  const [newBook, setNewBook] = useState({
    bookCover: '',
    bookName: '',
    authorName: '',
    publishYear: '',
    edition: '',
    pages: '',
    description: ''
  });
  const [isEditing, setIsEditing] = useState(false);
  const [editingBook, setEditingBook] = useState(null);
  const [selectedQuote, setSelectedQuote] = useState(null);
  const [notification, setNotification] = useState(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Notification display function
  const showNotification = (message, type = 'success') => {
    setNotification({ message, type });
    setTimeout(() => {
      setNotification(null);
    }, 3000);
  };

  useEffect(() => {
    fetchBooks();
  }, []);

  const fetchBooks = async () => {
    try {
      const response = await axios.get('http://localhost:3000/books');
      setBooks(response.data.books);
    } catch (error) {
      console.error('Error fetching books:', error);
      showNotification('Failed to fetch books', 'error');
    }
  };

  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewBook(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleAddBook = async (e) => {
    e.preventDefault();
    
    // Prevent multiple submissions
    if (isSubmitting) return;

    // Validate required fields
    if (!newBook.bookName || !newBook.authorName) {
      showNotification('Kitap Adı ve Yazar Adı gereklidir', 'error');
      return;
    }

    setIsSubmitting(true);

    try {
      const response = isEditing 
        ? await axios.put(`http://localhost:3000/books/${editingBook.id}`, newBook)
        : await axios.post('http://localhost:3000/books', newBook);
      
      console.log('Book add/update response:', response.data);
      
      // Ensure the response includes an ID
      if (!response.data.id) {
        throw new Error('Kitap kimliği alınamadı');
      }
      
      fetchBooks();
      
      // Show success notification
      showNotification(`${newBook.bookName} ${isEditing ? 'güncellendi' : 'eklendi'}`, 'success');
      
      // Reset form
      setNewBook({
        bookCover: '',
        bookName: '',
        authorName: '',
        publishYear: '',
        edition: '',
        pages: '',
        description: ''
      });
      setIsEditing(false);
      setEditingBook(null);
    } catch (error) {
      console.error('Kitap ekleme/güncelleme hatası:', error);
      showNotification('Kitap eklenemedi', 'error');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteBook = async (book) => {
    console.log('Attempting to delete book:', book);
    
    // Validate book object
    if (!book || !book.id) {
      console.error('Invalid book object for deletion:', book);
      showNotification('Geçersiz kitap bilgisi', 'error');
      return;
    }

    try {
      console.log(`Sending delete request for book ID: ${book.id}`);
      
      const response = await axios.delete(`http://localhost:3000/books/${book.id}`, {
        // Add timeout to catch potential network issues
        timeout: 10000,
        // Ensure proper headers
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      console.log('Delete response:', response.data);
      
      // Fetch books after successful deletion
      await fetchBooks();
      
      // Use book name in the success message
      const message = response.data.message || `${book.bookName} listeden silindi`;
      showNotification(message, 'success');
    } catch (error) {
      // Comprehensive error logging
      console.error('Detaylı silme hatası:', {
        response: error.response,
        request: error.request,
        message: error.message,
        config: error.config,
        status: error.response?.status,
        data: error.response?.data
      });
      
      // More detailed error message
      const errorMessage = 
        error.response?.data?.details || 
        error.response?.data?.error || 
        error.message ||
        'Kitap silinemedi';
      
      // Special handling for specific error types
      if (error.response) {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx
        switch (error.response.status) {
          case 404:
            showNotification('Kitap bulunamadı', 'error');
            break;
          case 400:
            showNotification('Geçersiz kitap silme isteği', 'error');
            break;
          case 500:
            showNotification('Sunucu hatası: Kitap silinemedi', 'error');
            break;
          default:
            showNotification(errorMessage, 'error');
        }
      } else if (error.request) {
        // The request was made but no response was received
        showNotification('Sunucuya bağlanılamadı', 'error');
      } else {
        // Something happened in setting up the request that triggered an Error
        showNotification('Bilinmeyen bir hata oluştu', 'error');
      }
    }
  };

  const handleEditBook = (book) => {
    setIsEditing(true);
    setEditingBook(book);
    setNewBook({
      bookCover: book.bookCover || '',
      bookName: book.bookName,
      authorName: book.authorName,
      publishYear: book.publishYear,
      edition: book.edition,
      pages: book.pages,
      description: book.description
    });
  };

  const handleQuoteUpload = async (bookId, event) => {
    const file = event.target.files[0];
    if (!file) {
      console.log('No file selected');
      showNotification('Please select a file to upload', 'error');
      return;
    }

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
    if (!allowedTypes.includes(file.type)) {
      console.error(`Invalid file type: ${file.type}`);
      showNotification('Only JPEG, PNG, and GIF images are allowed', 'error');
      return;
    }

    // Validate file size (5MB max)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      console.error(`File too large: ${file.size} bytes`);
      showNotification('File is too large. Maximum size is 5MB', 'error');
      return;
    }

    console.log(`Attempting to upload quote for book ID: ${bookId}`);
    console.log(`File details: ${JSON.stringify({
      name: file.name,
      type: file.type,
      size: file.size
    })}`);

    const formData = new FormData();
    formData.append('quote', file);

    try {
      const response = await axios.post(`http://localhost:3000/books/${bookId}/quotes`, formData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        // Add timeout to catch potential network issues
        timeout: 30000 // 30 seconds
      });
      
      console.log('Quote upload response:', response.data);
      
      // Refresh books to show the new quote
      await fetchBooks();
      
      showNotification('Quote uploaded successfully', 'success');
    } catch (error) {
      // Detailed error handling
      if (error.response) {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx
        console.error('Quote upload server error:', error.response.data);
        showNotification(
          error.response.data.details || 
          error.response.data.error || 
          'Failed to upload quote', 
          'error'
        );
      } else if (error.request) {
        // The request was made but no response was received
        console.error('No response received:', error.request);
        showNotification('No response from server. Please check your connection.', 'error');
      } else {
        // Something happened in setting up the request that triggered an Error
        console.error('Quote upload error:', error.message);
        showNotification('An unexpected error occurred', 'error');
      }
    }
  };

  const handleQuoteDelete = async (bookId, quoteUrl) => {
    try {
      await axios.delete(`http://localhost:3000/books/${bookId}/quotes`, {
        data: { quoteUrl }
      });
      fetchBooks();
      showNotification('Quote deleted successfully', 'success');
    } catch (error) {
      console.error('Error deleting quote:', error);
      showNotification('Failed to delete quote', 'error');
    }
  };

  const removeDuplicateBooks = async () => {
    try {
      const response = await axios.post('http://localhost:3000/books/remove-duplicates');
      
      console.log('Duplicate removal response:', response.data);
      
      // Fetch books after removing duplicates
      await fetchBooks();
      
      // Show notification about removed duplicates
      showNotification(
        `${response.data.removedBooks.length} adet duplicate kitap silindi`, 
        'success'
      );
    } catch (error) {
      console.error('Duplicate kitapları silme hatası:', error);
      showNotification('Duplicate kitaplar silinemedi', 'error');
    }
  };

  const listBookIds = async () => {
    try {
      const response = await axios.get('http://localhost:3000/books/list-ids');
      console.log('Book IDs:', response.data);
      
      // Display book IDs in a more readable format
      const bookList = response.data.books.map(book => 
        `ID: ${book.id}, Name: ${book.bookName}, Author: ${book.authorName}`
      ).join('\n');
      
      showNotification(`Total Books: ${response.data.totalBooks}\n${bookList}`, 'info');
    } catch (error) {
      console.error('Error listing book IDs:', error);
      showNotification('Kitap kimlikleri listelenemedi', 'error');
    }
  };

  const syncBooksToJSON = async () => {
    try {
      console.log('Starting book sync...');
      
      // Log request details
      console.log('Sync Request Details:', {
        url: 'http://localhost:3000/books/sync',
        method: 'POST',
        timeout: 30000
      });

      const response = await axios({
        method: 'post',
        url: 'http://localhost:3000/books/sync',
        timeout: 30000,
        headers: {
          'Content-Type': 'application/json'
        }
      });
      
      console.log('Book sync response:', response.data);
      
      // Construct detailed notification message
      let notificationMessage = `${response.data.totalBooks} kitap JSON dosyasında mevcut`;
      
      // Added books
      if (response.data.addedBooks && response.data.addedBooks.length > 0) {
        const addedBookNames = response.data.addedBooks.map(book => 
          `${book.bookName} (${book.authorName})`
        ).join(', ');
        
        notificationMessage += `\n${response.data.addedBooks.length} kitap eklendi: ${addedBookNames}`;
      }
      
      // Removed books
      if (response.data.removedBooks && response.data.removedBooks.length > 0) {
        const removedBookNames = response.data.removedBooks.map(book => 
          `${book.bookName} (${book.authorName})`
        ).join(', ');
        
        notificationMessage += `\n${response.data.removedBooks.length} kitap silindi: ${removedBookNames}`;
      }
      
      showNotification(notificationMessage, 'success');
      
      // Refresh books after sync
      await fetchBooks();
    } catch (error) {
      console.error('Kitapları senkronize etme hatası:', {
        message: error.message,
        response: error.response,
        request: error.request,
        config: error.config,
        status: error.response?.status,
        data: error.response?.data,
        headers: error.config?.headers
      });

      // More detailed error message
      const errorMessage = 
        error.response?.data?.details || 
        error.response?.data?.error || 
        error.message ||
        'Kitaplar senkronize edilemedi';
      
      showNotification(errorMessage, 'error');
    }
  };

  return (
    <div style={{ 
      maxWidth: '800px', 
      margin: 'auto', 
      padding: '20px', 
      fontFamily: 'Arial, sans-serif' 
    }}>
      {/* Notification System */}
      {notification && (
        <div 
          style={{
            position: 'fixed',
            top: '20px',
            right: '20px',
            padding: '15px',
            backgroundColor: notification.type === 'success' ? '#4CAF50' : '#F44336',
            color: 'white',
            borderRadius: '4px',
            zIndex: 1000,
            boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
          }}
        >
          {notification.message}
        </div>
      )}

      <h1 style={{ 
        textAlign: 'center', 
        color: '#333', 
        borderBottom: '2px solid #4CAF50', 
        paddingBottom: '10px' 
      }}>
        KesitOkur Admin Dashboard
      </h1>
      
      <form 
        onSubmit={handleAddBook} 
        style={{ 
          display: 'grid', 
          gridTemplateColumns: '1fr 1fr', 
          gap: '15px', 
          marginBottom: '30px',
          background: '#f4f4f4',
          padding: '20px',
          borderRadius: '8px'
        }}
      >
        <input
          type="text"
          name="bookName"
          placeholder="Book Name"
          value={newBook.bookName}
          onChange={handleInputChange}
          required
          style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ddd' }}
        />
        <input
          type="text"
          name="authorName"
          placeholder="Author Name"
          value={newBook.authorName}
          onChange={handleInputChange}
          required
          style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ddd' }}
        />
        <input
          type="text"
          name="publishYear"
          placeholder="Publish Year"
          value={newBook.publishYear}
          onChange={handleInputChange}
          style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ddd' }}
        />
        <input
          type="text"
          name="edition"
          placeholder="Edition"
          value={newBook.edition}
          onChange={handleInputChange}
          style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ddd' }}
        />
        <input
          type="text"
          name="pages"
          placeholder="Number of Pages"
          value={newBook.pages}
          onChange={handleInputChange}
          style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ddd' }}
        />
        <input
          type="text"
          name="bookCover"
          placeholder="Book Cover URL"
          value={newBook.bookCover}
          onChange={handleInputChange}
          style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ddd' }}
        />
        <textarea
          name="description"
          placeholder="Book Description"
          value={newBook.description}
          onChange={handleInputChange}
          style={{ 
            gridColumn: '1 / -1', 
            padding: '10px', 
            borderRadius: '4px', 
            border: '1px solid #ddd',
            minHeight: '100px'
          }}
        />
        <button 
          type="submit" 
          disabled={isSubmitting}
          style={{ 
            gridColumn: '1 / -1',
            padding: '12px', 
            backgroundColor: isEditing ? '#FFA500' : '#4CAF50', 
            color: 'white', 
            border: 'none',
            borderRadius: '4px',
            cursor: isSubmitting ? 'not-allowed' : 'pointer',
            opacity: isSubmitting ? 0.5 : 1
          }}
        >
          {isSubmitting ? 'Submitting...' : (isEditing ? 'Update Book' : 'Add Book')}
        </button>
      </form>

      <div>
        <h2 style={{ 
          color: '#333', 
          borderBottom: '1px solid #4CAF50', 
          paddingBottom: '10px' 
        }}>
          Book List
        </h2>
        {books.map(book => (
          <div 
            key={book.id} 
            style={{ 
              border: '1px solid #ddd', 
              padding: '15px', 
              marginBottom: '15px',
              borderRadius: '8px',
              display: 'flex',
              gap: '20px',
              alignItems: 'center',
              backgroundColor: '#f9f9f9'
            }}
          >
            {book.bookCover && (
              <img 
                src={book.bookCover} 
                alt={`Cover of ${book.bookName}`}
                style={{ 
                  width: '100px', 
                  height: '150px', 
                  objectFit: 'cover', 
                  borderRadius: '4px',
                  boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
                }} 
              />
            )}
            <div style={{ flex: 1 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <h3 style={{ margin: 0, color: '#333' }}>{book.bookName}</h3>
                <div style={{ display: 'flex', gap: '10px' }}>
                  <button 
                    onClick={() => handleEditBook(book)}
                    style={{ 
                      backgroundColor: '#2196F3', 
                      color: 'white', 
                      border: 'none', 
                      padding: '8px 15px',
                      borderRadius: '4px',
                      cursor: 'pointer'
                    }}
                  >
                    Edit
                  </button>
                  <button 
                    onClick={() => handleDeleteBook(book)}
                    style={{ 
                      backgroundColor: '#F44336', 
                      color: 'white', 
                      border: 'none', 
                      padding: '8px 15px',
                      borderRadius: '4px',
                      cursor: 'pointer'
                    }}
                  >
                    Delete
                  </button>
                </div>
              </div>
              <p style={{ color: '#666', margin: '5px 0' }}>
                <strong>Author:</strong> {book.authorName}
              </p>
              <p style={{ color: '#666', margin: '5px 0' }}>
                <strong>Published:</strong> {book.publishYear} | <strong>Edition:</strong> {book.edition}
              </p>
              <p style={{ fontSize: '0.9em', color: '#888', marginTop: '10px' }}>
                {book.description}
              </p>

              {/* Quote Management Section */}
              <div style={{ marginTop: '15px' }}>
                <h4>Book Quotes</h4>
                <div style={{ display: 'flex', gap: '10px', marginBottom: '10px' }}>
                  <input 
                    type="file" 
                    accept="image/*"
                    onChange={(e) => handleQuoteUpload(book.id, e)}
                  />
                </div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '10px' }}>
                  {book.excerpts && book.excerpts.map((quoteUrl, index) => (
                    <div 
                      key={index} 
                      style={{ 
                        position: 'relative', 
                        width: '100px', 
                        height: '100px' 
                      }}
                    >
                      <img 
                        src={quoteUrl} 
                        alt={`Quote ${index + 1}`}
                        style={{ 
                          width: '100%', 
                          height: '100%', 
                          objectFit: 'cover', 
                          borderRadius: '4px' 
                        }}
                      />
                      <button
                        onClick={() => handleQuoteDelete(book.id, quoteUrl)}
                        style={{
                          position: 'absolute',
                          top: '5px',
                          right: '5px',
                          backgroundColor: 'rgba(255,0,0,0.7)',
                          color: 'white',
                          border: 'none',
                          borderRadius: '50%',
                          width: '25px',
                          height: '25px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          cursor: 'pointer'
                        }}
                      >
                        ×
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        ))}
        <button 
          onClick={removeDuplicateBooks}
          style={{ 
            padding: '12px', 
            backgroundColor: '#4CAF50', 
            color: 'white', 
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer'
          }}
        >
          Remove Duplicate Books
        </button>
        <button 
          onClick={listBookIds}
          style={{ 
            padding: '12px', 
            backgroundColor: '#4CAF50', 
            color: 'white', 
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer'
          }}
        >
          List Book IDs
        </button>
        <button 
          onClick={syncBooksToJSON}
          style={{ 
            padding: '12px', 
            backgroundColor: '#4CAF50', 
            color: 'white', 
            border: 'none',
            borderRadius: '4px',
            cursor: 'pointer'
          }}
        >
          Sync Books to JSON
        </button>
      </div>
    </div>
  );
}

export default App;
