const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Verify service account key exists
const serviceAccountPath = './backend/firebase/serviceAccountKey.json';
if (!fs.existsSync(serviceAccountPath)) {
  console.error('Firebase service account key not found at:', serviceAccountPath);
  process.exit(1);
}

// Initialize Firebase Admin
const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: 'gs://kesitokur-app.firebasestorage.app'  // Updated bucket path
});

const db = admin.firestore();
const bucket = admin.storage().bucket();

const BOOK_IDS = {
  'TED Gibi Konuş': 'V2PLcuusOPSx6TCRY4Eo',
  'Dost Kazanma ve İnsanları Etkileme Sanatı': '9I1UrwwetufmBEdvJtrG',
  'İnsan Doğasının Yasaları': '2djjVabbPui18HiEDDeH',
  'Insan Doğasının Yasaları': '2djjVabbPui18HiEDDeH'
};

const QUOTES_BASE_DIR = '/Users/muratisik/Desktop/KesitOkurr';

async function uploadQuotesForBook(bookName, bookId) {
  // Try both original and alternative directory names
  const possibleDirs = [
    path.join(QUOTES_BASE_DIR, bookName),
    path.join(QUOTES_BASE_DIR, bookName.replace('İ', 'I'))
  ];

  let quotesDir = null;
  for (const dir of possibleDirs) {
    if (fs.existsSync(dir)) {
      quotesDir = dir;
      break;
    }
  }

  if (!quotesDir) {
    console.error(`No directory found for book: ${bookName}`);
    return;
  }

  const quoteFiles = fs.readdirSync(quotesDir)
    .filter(file => file.endsWith('.jpg') || file.endsWith('.png') || file.endsWith('.jpeg'));

  console.log(`Uploading ${quoteFiles.length} quotes for ${bookName}`);

  for (const quoteFile of quoteFiles) {
    const filePath = path.join(quotesDir, quoteFile);
    const filename = `quotes/${bookId}/${Date.now()}_${quoteFile}`;

    try {
      // Verify bucket exists before upload
      const [bucketExists] = await bucket.exists();
      if (!bucketExists) {
        console.error('Firebase Storage bucket does not exist!');
        console.error('Bucket details:', bucket.name);
        continue;
      }

      // Upload to Firebase Storage
      const [uploadResponse] = await bucket.upload(filePath, {
        destination: filename,
        metadata: {
          contentType: 'image/jpeg'
        }
      });

      // Make the file public
      await uploadResponse.makePublic();

      // Get public URL
      const publicUrl = uploadResponse.publicUrl();

      // Get book document
      const bookDoc = await db.collection('books').doc(bookId).get();
      const bookData = bookDoc.data();

      // Add quote to book's quotes array
      const updatedQuotes = [...(bookData.quotes || []), {
        url: publicUrl,
        tags: [], // You can add tags here if needed
        uploadedAt: new Date().toISOString()
      }];

      // Update book document
      await db.collection('books').doc(bookId).update({
        quotes: updatedQuotes
      });

      console.log(`Uploaded quote: ${quoteFile}`);
    } catch (error) {
      console.error(`Error uploading quote ${quoteFile} for ${bookName}:`, error);
      console.error('Error details:', JSON.stringify(error, null, 2));
    }
  }
}

async function uploadAllQuotes() {
  try {
    for (const [bookName, bookId] of Object.entries(BOOK_IDS)) {
      try {
        await uploadQuotesForBook(bookName, bookId);
      } catch (bookError) {
        console.error(`Failed to upload quotes for ${bookName}:`, bookError);
      }
    }
    console.log('Quote upload completed');
  } catch (overallError) {
    console.error('Overall upload process failed:', overallError);
  } finally {
    process.exit(0);
  }
}

uploadAllQuotes().catch(console.error);
