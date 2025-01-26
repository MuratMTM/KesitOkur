# Quote Image Upload Guide

## Directory Structure
Create a `quotes` directory in this project folder with subdirectories for each book's quotes:

```
KesitOkur/
└── quotes/
    ├── book1_id/
    │   ├── quote1.jpg
    │   ├── quote2.jpg
    │   └── quote3.jpg
    ├── book2_id/
    │   ├── quote1.jpg
    │   └── quote2.jpg
    └── ...
```

## Upload Process
1. Ensure each book has a unique `id` in your `kesitokur-app-books.json`
2. Create a subdirectory in the `quotes` folder matching the book's `id`
3. Add quote images to this subdirectory
4. Run `node uploadDataToFirestore.js`

## Image Recommendations
- Use high-quality, readable quote images
- Recommended formats: JPG, PNG
- Suggested image size: 1080x1080 pixels
- Ensure text is clear and legible

## Firestore Storage
- Quote images are uploaded to Firebase Storage
- Quote URLs are stored in the corresponding book's Firestore document
- Users can favorite quotes, which are saved in their personal collection
