const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "kesitokur-app.firebasestorage.app"
});

const bucket = admin.storage().bucket();

async function moveFiles() {
  try {
    console.log("Listing files in quotes/6/ directory...");
    const [files] = await bucket.getFiles({ prefix: 'quotes/6/' });
    
    console.log(`Found ${files.length} files to move`);
    
    for (const file of files) {
      const oldPath = file.name;
      const newPath = oldPath.replace('quotes/6/', 'quotes/5/');
      
      console.log(`Moving ${oldPath} to ${newPath}`);
      
      try {
        // Copy the file to new location
        await bucket.file(oldPath).copy(bucket.file(newPath));
        console.log(`✓ Copied to ${newPath}`);
        
        // Delete the original file
        await bucket.file(oldPath).delete();
        console.log(`✓ Deleted original from ${oldPath}`);
      } catch (error) {
        console.error(`Error moving file ${oldPath}:`, error);
      }
    }
    
    console.log("\nFile movement completed!");
    
  } catch (error) {
    console.error("Error during file movement:", error);
  }
}

// Run the script
console.log("Starting file movement process...");
moveFiles()
  .then(() => {
    console.log("Process completed successfully!");
    process.exit(0);
  })
  .catch(error => {
    console.error("Process failed:", error);
    process.exit(1);
  });
