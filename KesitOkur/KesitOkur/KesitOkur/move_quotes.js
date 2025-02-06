const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "kesitokur-app.firebasestorage.app"
});

const db = admin.firestore();

async function moveQuotes() {
  try {
    // Get the source book (ID 6)
    const sourceDoc = await db.collection("books").doc("6").get();
    if (!sourceDoc.exists) {
      console.log("Source book (ID 6) not found!");
      return;
    }

    // Get the quotes array
    const sourceData = sourceDoc.data();
    const excerpts = sourceData.excerpts || [];

    if (excerpts.length === 0) {
      console.log("No excerpts found in source book!");
      console.log("Available fields:", Object.keys(sourceData));
      return;
    }

    console.log(`Found ${excerpts.length} excerpts to move`);

    // Update the target book (ID 5)
    await db.collection("books").doc("5").update({
      excerpts: excerpts,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log("✓ Successfully moved excerpts to book ID 5");

    // Clear excerpts from source book
    await db.collection("books").doc("6").update({
      excerpts: [],
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log("✓ Cleared excerpts from book ID 6");

  } catch (error) {
    console.error("Error moving quotes:", error);
  }
}

// Run the script
console.log("Starting quote transfer...");
moveQuotes()
  .then(() => {
    console.log("Transfer completed!");
    process.exit(0);
  })
  .catch(error => {
    console.error("Error:", error);
    process.exit(1);
  });
