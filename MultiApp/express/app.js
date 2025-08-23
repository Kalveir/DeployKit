// Import the express module
const express = require('express');

// Create an Express application instance
const app = express();

// Define the port to be used
const PORT = 8686;

// Define a GET route for '/hello'
app.get('/', (req, res) => {
  // Send a JSON response with status 200
  res.status(200).json({ message: 'hello world' });
});

// Start the Express server
app.listen(PORT, () => {
  console.log(`Express server running on http://localhost:${PORT}`);
});

