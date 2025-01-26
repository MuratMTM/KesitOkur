const fs = require('fs-extra');
const path = require('path');

const books = require('./kesitokur-app-books.json').books;

async function prepareQuoteDirectories() {
    const quotesBaseDir = path.join(__dirname, 'quotes');
    
    // Ensure quotes base directory exists
    await fs.ensureDir(quotesBaseDir);

    for (const book of books) {
        const bookQuoteDir = path.join(quotesBaseDir, book.id);
        
        // Create directory for each book's quotes
        await fs.ensureDir(bookQuoteDir);
        
        console.log(`Created quote directory for book: ${book.bookName} (ID: ${book.id})`);
    }

    console.log('Quote directories preparation complete!');
}

prepareQuoteDirectories().catch(console.error);
