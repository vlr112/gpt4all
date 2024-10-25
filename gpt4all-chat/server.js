const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = 3000;

// Middleware to parse JSON data
app.use(express.json());

// Define the base directory where folders will be created
const baseDirectory = "C:/Users/franc/OneDrive/Francisca_Denmark/Internship";  // Update this to your desired path

// Endpoint to save HTML content in a new folder
app.post('/saveHtml', (req, res) => {
    const { collectionName, linksData } = req.body;

    // Define the path for the new folder
    const folderPath = path.join(baseDirectory, collectionName);

    // Create the folder if it doesn't exist
    if (!fs.existsSync(folderPath)) {
        fs.mkdirSync(folderPath, { recursive: true });
    }

    // Save each HTML content as a separate file
    linksData.forEach((item, index) => {
        const fileName = `page_${index + 1}.html`;
        const filePath = path.join(folderPath, fileName);

        fs.writeFile(filePath, item.html, (err) => {
            if (err) {
                console.error(`Error saving file ${fileName}:`, err);
            } else {
                console.log(`File saved: ${fileName}`);
            }
        });
    });

    res.status(200).json({ message: 'HTML files saved successfully.' });
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const PORT = 3000;

// Middleware to parse JSON data
app.use(express.json());

// Endpoint to save HTML content in a new folder
app.post('/saveHtml', (req, res) => {
    const { collectionName, linksData } = req.body;

    // Define the path for the new folder
    const folderPath = path.join(__dirname, 'LocalDocs', collectionName);

    // Create the folder if it doesn't exist
    if (!fs.existsSync(folderPath)) {
        fs.mkdirSync(folderPath, { recursive: true });
    }

    // Save each HTML content as a separate file
    linksData.forEach((item, index) => {
        const fileName = `page_${index + 1}.html`;
        const filePath = path.join(folderPath, fileName);

        fs.writeFile(filePath, item.html, (err) => {
            if (err) {
                console.error(`Error saving file ${fileName}:`, err);
            } else {
                console.log(`File saved: ${fileName}`);
            }
        });
    });

    res.status(200).json({ message: 'HTML files saved successfully.' });
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
