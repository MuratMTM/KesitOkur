const admin = require("firebase-admin");
const fs = require('fs-extra');
const path = require('path');

// Firebase Admin SDK initialization
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "kesitokur-app.appspot.com"
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

// Configuration
const BOOKS_SOURCE_DIR = "/Users/muratisik/Desktop/KesitOkurr";

// Helper function to convert folder name to Firebase-friendly ID
function generateBookId(folderName) {
    return folderName.toLowerCase()
        .replace(/\s+/g, '-')           // Replace spaces with hyphens
        .replace(/[^a-z0-9-]/g, '')     // Remove any characters that aren't letters, numbers, or hyphens
        .replace(/-+/g, '-')            // Replace multiple consecutive hyphens with a single hyphen
        .replace(/^-|-$/g, '');         // Remove leading and trailing hyphens
}

// Function to upload quote images for a book
async function uploadQuoteImages(bookFolder, bookId) {
    try {
        const sourcePath = path.join(BOOKS_SOURCE_DIR, bookFolder);
        const files = await fs.readdir(sourcePath);
        const imageFiles = files.filter(file => 
            ['.jpg', '.jpeg', '.png'].includes(path.extname(file).toLowerCase()) &&
            !file.startsWith('.')  // Exclude hidden files like .DS_Store
        );

        const quotes = [];
        console.log(`Processing ${imageFiles.length} quotes for ${bookFolder}...`);

        for (const file of imageFiles) {
            const filePath = path.join(sourcePath, file);
            const destination = `quotes/${bookId}/${file}`;

            try {
                // Check if file already exists in Firebase Storage
                const [exists] = await bucket.file(destination).exists();
                
                if (!exists) {
                    // Upload image to Firebase Storage
                    await bucket.upload(filePath, {
                        destination: destination,
                        metadata: {
                            contentType: `image/${path.extname(file).slice(1)}`,
                        }
                    });
                    console.log(`✓ Uploaded new file: ${file}`);
                } else {
                    console.log(`• Skipped existing file: ${file}`);
                }

                // Get public URL
                const [url] = await bucket.file(destination).getSignedUrl({
                    version: 'v4',
                    action: 'read',
                    expires: Date.now() + 365 * 24 * 60 * 60 * 1000, // 1 year
                });

                quotes.push({
                    url: url,
                    name: file,
                    timestamp: admin.firestore.FieldValue.serverTimestamp()
                });
            } catch (error) {
                console.error(`Error processing ${file}:`, error);
            }
        }

        return quotes;
    } catch (error) {
        console.error(`Error processing quotes for ${bookFolder}:`, error);
        return [];
    }
}

// Main function to sync all books
async function syncBooks() {
    try {
        // Get all folders in the source directory
        const items = await fs.readdir(BOOKS_SOURCE_DIR, { withFileTypes: true });
        const bookFolders = items
            .filter(item => item.isDirectory() && !item.name.startsWith('.'))
            .map(item => item.name);

        console.log(`Found ${bookFolders.length} book folders to process`);

        for (const bookFolder of bookFolders) {
            console.log(`\nProcessing book folder: ${bookFolder}`);
            const bookId = generateBookId(bookFolder);
            
            try {
                // Get or create book document
                const bookRef = db.collection("books").doc(bookId);
                const bookDoc = await bookRef.get();
                
                if (!bookDoc.exists) {
                    // Create new book document
                    await bookRef.set({
                        id: bookId,
                        bookName: bookFolder,
                        quotes: [],
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });
                    console.log(`Created new book document for ${bookFolder}`);
                }

                // Upload and process quotes
                const quotes = await uploadQuoteImages(bookFolder, bookId);
                
                if (quotes.length > 0) {
                    // Get existing quotes to avoid duplicates
                    const existingDoc = await bookRef.get();
                    const existingQuotes = existingDoc.data()?.quotes || [];
                    const existingNames = new Set(existingQuotes.map(q => q.name));
                    
                    // Filter out quotes that already exist
                    const newQuotes = quotes.filter(quote => !existingNames.has(quote.name));
                    
                    if (newQuotes.length > 0) {
                        // Update book document with new quotes
                        await bookRef.update({
                            quotes: admin.firestore.FieldValue.arrayUnion(...newQuotes),
                            updatedAt: admin.firestore.FieldValue.serverTimestamp()
                        });
                        console.log(`✓ Added ${newQuotes.length} new quotes to ${bookFolder}`);
                    } else {
                        console.log(`• No new quotes to add for ${bookFolder}`);
                    }
                }
            } catch (error) {
                console.error(`Error processing book ${bookFolder}:`, error);
            }
        }
    } catch (error) {
        console.error('Error reading source directory:', error);
    }
}

// Run the sync process
console.log(`Starting quote sync process from ${BOOKS_SOURCE_DIR}`);
syncBooks()
    .then(() => {
        console.log('\nSync process completed successfully!');
        process.exit(0);
    })
    .catch(error => {
        console.error('Error in sync process:', error);
        process.exit(1);
    });
