# Quote Image Guidelines

## Directory Structure
Each book has a dedicated directory named by its book ID:
```
quotes/
├── 1/     # İktidar Güç Sahibi Olmanın 48 Yasası
├── 2/     # Elon Musk
├── 3/     # 10X Kuralı
...
```

## Image Requirements
- Format: JPG or PNG
- Size: 1080x1080 pixels
- Naming Convention: `quote1.jpg`, `quote2.jpg`, etc.
- Content: Meaningful quote from the book
- Readability: Clear, high-contrast text

## Uploading Process
1. Create quote images for a book
2. Place images in the corresponding book ID directory
3. Run `node uploadDataToFirestore.js`

## Example
For the book "İktidar Güç Sahibi Olmanın 48 Yasası" (ID: 1):
```
quotes/1/quote1.jpg
quotes/1/quote2.jpg
quotes/1/quote3.jpg
```

## Tips
- Use design tools like Canva or Adobe Spark
- Ensure quotes are legally permissible
- Aim for visually appealing and inspirational designs
