// src/routes/userRoutes.js
const express = require('express');
const moment = require('moment');
const router = express.Router();
const userController = require('../controllers/userController');
const tesseract = require('tesseract.js');
const crypto = require('crypto');
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
      JOIN plan AS p ON up.plan_name = p.name
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

router.post('/payment', (req, res) => {
  const { userEmail, plan_name, price_paid } = req.body;

  // Fetch the selected plan details
  db.query('SELECT * FROM plan WHERE name = ?', [plan_name], (err, planResult) => {
    if (err) {
      return res.status(500).json({ error: 'Error fetching plan details' });
    }

    const plan = planResult[0];
    if (!plan) {
      return res.status(400).json({ error: 'Plan not found' });
    }

    const currentDate = moment().format('YYYY-MM-DD');
    const startDate = currentDate;
    const endDate = moment().add(plan.frequency === '/month' ? 1 : plan.frequency === '/3 month' ? 3 : 12, 'months').format('YYYY-MM-DD');
    const reportUploadLimit = plan.report_upload_limit;

    // Insert purchase record
    const purchaseQuery = `
      INSERT INTO userplan (user_email, plan_name, price_paid, purchase_date, start_date, end_date, status, reports_uploaded)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `;
    const purchaseValues = [
      userEmail,
      plan_name,
      price_paid,
      currentDate,
      startDate,
      endDate,
      'active', // Status is 'active' immediately after payment
      0, // Initially, no reports are uploaded
    ];

    db.query(purchaseQuery, purchaseValues, (err, result) => {
      if (err) {
        return res.status(500).json({ error: 'Error processing payment' });
      }

      return res.status(200).json({ message: 'Payment successful', subscriptionId: result.insertId });
    });
  });
});

router.post('/submit-report', async (req, res) => {
  const { user_email, doctor_email, report_type, file_data } = req.body;

  if (!user_email || !doctor_email || !report_type || !file_data) {
    return res.status(400).json({ error: 'All fields are required.' });
  }

  try {
    // Decode the file data
    const buffer = Buffer.from(file_data, 'base64');

    

    // Check if user has an active plan and remaining upload limit
    const planQuery = `
      SELECT * FROM userplan
      WHERE user_email = ? AND status = 'active' AND end_date >= CURDATE()
      LIMIT 1
    `;
    const [planResult] = await db.promise().query(planQuery, [user_email]);

    if (planResult.length === 0) {
      return res.status(403).json({ error: 'No active plan found for the user.' });
    }

    const userPlan = planResult[0];
    const remainingReports = userPlan.report_upload_limit - userPlan.reports_uploaded;

    if (remainingReports <= 0) {
      return res.status(403).json({ error: 'Report upload limit reached for the active plan.' });
    }

    // Insert the medical report into the database
    const reportQuery = `
      INSERT INTO medical_reports (user_email, doctor_email, report_type, file_data)
      VALUES (?, ?, ?, ?)
    `;
    await db.promise().query(reportQuery, [user_email, doctor_email, report_type, buffer]);

    // Update the reports_uploaded count in the user's plan
    const updatePlanQuery = `
      UPDATE userplan
      SET reports_uploaded = reports_uploaded + 1
      WHERE id = ?
    `;
    await db.promise().query(updatePlanQuery, [userPlan.id]);

    res.status(200).json({
      message: 'Report submitted successfully and seal validated.',
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Internal server error.' });
  }
});


module.exports = router;

