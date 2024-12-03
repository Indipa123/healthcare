// src/routes/userRoutes.js
const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const db = require('../config/db');

// Define routes for user-related actions
router.get('/', userController.getAllUsers);
router.post('/', userController.createUser);

// Update profile image
router.post('/upload', (req, res) => {
    const { email, image } = req.body;
    const query = 'UPDATE users SET image = ? WHERE email = ?';
    db.query(query, [Buffer.from(image, 'base64'), email], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Image updated successfully' });
    });
  });

  
router.get('/user/image', (req, res) => {
    const { email } = req.query;
    const query = 'SELECT image FROM users WHERE email = ?';
  
    db.query(query, [email], (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
  
      if (results.length > 0 && results[0].image) {
        const imageBuffer = results[0].image;
  
        // Set headers for content type and disposition to trigger download
        res.setHeader('Content-Type', 'image/jpeg'); // or 'image/png' depending on the image format
        res.setHeader('Content-Disposition', 'attachment; filename="user-image.jpg"'); // Customize file name and extension as needed
        res.status(200).send(imageBuffer);
      } else {
        res.status(404).json({ message: 'Image not found' });
      }
    });
  });
    


module.exports = router;

