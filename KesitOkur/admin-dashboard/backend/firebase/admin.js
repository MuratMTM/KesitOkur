const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Check if Firebase is already initialized
if (!admin.apps.length) {
  try {
    // Path to service account key
    const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
    
    // Check if service account key exists
    if (!fs.existsSync(serviceAccountPath)) {
      throw new Error('Firebase service account key not found');
    }

    const serviceAccount = require(serviceAccountPath);

    // Initialize Firebase Admin
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      storageBucket: 'kesitokur-app.appspot.com'
    });

    console.log('Firebase Admin initialized successfully');
  } catch (error) {
    console.error('Firebase initialization error:', error.message);
    process.exit(1);
  }
}

// Get Firestore and Storage instances
const db = admin.firestore();
const bucket = admin.storage().bucket();

// Optional: Add some basic validation
if (!db) {
  console.error('Firestore database could not be initialized');
  process.exit(1);
}

if (!bucket) {
  console.error('Firebase Storage bucket could not be initialized');
  process.exit(1);
}

module.exports = {
  admin,
  db,
  bucket
};
