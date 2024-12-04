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

router.post('/user/check-plan', (req, res) => {
    const { email } = req.body;

    console.log('Request body:', req.body);
  
    // Validate request body
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }
  
    // Query to check active user plan and associated report upload limits
    const query = `
      SELECT up.*, p.report_upload_limit, p.name AS plan_name
      FROM userplan AS up
      JOIN plan AS p ON up.plan_id = p.id
      WHERE up.user_email = ? AND up.status = 'active' AND up.end_date >= CURDATE()
      LIMIT 1;
    `;
  
    // Execute the query
    db.query(query, [email], (err, results) => {
      if (err) {
        console.error('Error querying database:', err);
        return res.status(500).json({ error: 'Internal Server Error' });
      }
  
      // Check if a valid plan exists
      if (results.length === 0) {
        return res.status(404).json({ error: 'No active plan found' });
      }
  
      const userPlan = results[0];
      const remainingReports = userPlan.report_upload_limit - userPlan.reports_uploaded;
  
      // Determine eligibility based on remaining upload limits
      if (remainingReports > 0) {
        return res.status(200).json({
          success: true,
          message: 'User is eligible to upload a medical report',
          remainingReports,
        });
      } else {
        return res.status(403).json({
          success: false,
          message: 'Report upload limit reached',
        });
      }
    });
  });  


module.exports = router;

