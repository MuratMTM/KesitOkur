const axios = require('axios');

const bookNames = [
    'TED Gibi Konuş', 
    'Dost Kazanma ve İnsanları Etkileme Sanatı'
];

async function findBookIdByName(bookName) {
    try {
        console.log(`Searching for book: "${bookName}"`);
        const response = await axios.get(`http://localhost:3000/books/search`, {
            params: { name: bookName, exact: true }
        });
        return response.data.bookId;
    } catch (error) {
        console.error(`Error finding book ID for ${bookName}:`, error.response ? error.response.data : error.message);
        return null;
    }
}

async function testQuoteRetrieval(bookName) {
    const bookId = await findBookIdByName(bookName);
    
    if (!bookId) {
        console.error(`Could not find book ID for ${bookName}`);
        return;
    }

    try {
        const response = await axios.get(`http://localhost:3000/books/${bookId}/quotes`);
        console.log('Quote Retrieval Test Results for', bookName);
        console.log('Total Quotes:', response.data.totalQuotes);
        console.log('Book Name:', response.data.bookName);
        console.log('First Quote URL:', response.data.quotes[0]?.url || 'No quotes');
        console.log('---');
    } catch (error) {
        console.error('Error retrieving quotes:', error.response ? error.response.data : error.message);
    }
}

async function runTests() {
    for (const bookName of bookNames) {
        await testQuoteRetrieval(bookName);
    }
}

runTests();
