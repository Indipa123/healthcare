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
    const endDate = moment()
      .add(plan.frequency === '/month' ? 1 : plan.frequency === '/3 month' ? 3 : 12, 'months')
      .format('YYYY-MM-DD');

    // Check if the user already has an active plan
    const checkPlanQuery = `
      SELECT * FROM userplan 
      WHERE user_email = ? AND status = 'active' AND end_date >= CURDATE()
      LIMIT 1;
    `;

    db.query(checkPlanQuery, [userEmail], (err, existingPlanResult) => {
      if (err) {
        return res.status(500).json({ error: 'Error checking existing subscription' });
      }

      if (existingPlanResult.length > 0) {
        // If an active plan exists, update it
        const updatePlanQuery = `
          UPDATE userplan 
          SET plan_name = ?, price_paid = ?, purchase_date = ?, start_date = ?, end_date = ?, reports_uploaded = 0 
          WHERE user_email = ? AND status = 'active' AND end_date >= CURDATE();
        `;
        const updateValues = [plan_name, price_paid, currentDate, startDate, endDate, userEmail];

        db.query(updatePlanQuery, updateValues, (err) => {
          if (err) {
            return res.status(500).json({ error: 'Error updating subscription' });
          }

          return res.status(200).json({ message: 'Subscription updated successfully' });
        });
      } else {
        // If no active plan exists, create a new one
        const insertPlanQuery = `
          INSERT INTO userplan (user_email, plan_name, price_paid, purchase_date, start_date, end_date, status, reports_uploaded)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;
        const insertValues = [
          userEmail,
          plan_name,
          price_paid,
          currentDate,
          startDate,
          endDate,
          'active', // Status is 'active' immediately after payment
          0, // Initially, no reports are uploaded
        ];

        db.query(insertPlanQuery, insertValues, (err, result) => {
          if (err) {
            return res.status(500).json({ error: 'Error processing payment' });
          }

          return res.status(200).json({ message: 'Payment successful', subscriptionId: result.insertId });
        });
      }
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

router.get('/reports/latest', (req, res) => {
  const { user_email } = req.query;

  // Check if user_email is provided
  if (!user_email) {
    return res.status(400).json({ error: 'User email is required' });
  }

  // Query to fetch the latest 5 reports for the given user
  const query = `
    SELECT id, report_type, status,DATE_FORMAT(created_at, '%Y-%m-%d') as created_at
    FROM medical_reports
    WHERE user_email = ?
    ORDER BY created_at DESC
    LIMIT 5
  `;

  // Execute the query
  db.query(query, [user_email], (err, results) => {
    if (err) {
      console.error('Error fetching reports:', err);
      return res.status(500).json({ error: 'Failed to fetch reports' });
    }

    // Respond with the fetched results
    res.status(200).json(results);
  });
});

// Fetch prescription details by prescription ID
router.get('/prescriptions/:report_id', (req, res) => {
  const reportId = req.params.report_id;

  // First, check the status of the report in the medical_reports table
  const statusQuery = `
    SELECT status
    FROM medical_reports
    WHERE id = ?
  `;

  db.query(statusQuery, [reportId], (err, statusResults) => {
    if (err) return res.status(500).json({ error: err.message });

    if (statusResults.length === 0) {
      return res.status(404).json({ error: 'Report not found' });
    }

    const status = statusResults[0].status;

    if (status !== 'View Report Feedback') {
      return res.status(200).json({ message: 'Pending Result' });
    }

    // If the status is 'View Report Feedback', fetch the prescription details
    const query = `
      SELECT prescription_details, prescription_image, feedback
      FROM feedback
      WHERE report_id = ?
    `;

    db.query(query, [reportId], (err, results) => {
      if (err) return res.status(500).json({ error: err.message });

      if (results.length === 0) {
        return res.status(404).json({ error: 'Prescription not found' });
      }

      const prescription = results[0];
      if (prescription.prescription_image) {
        prescription.prescriptionImage = Buffer.from(prescription.prescription_image).toString('base64');
      }

      res.status(200).json(prescription);
    });
  });
});


function calculateAge(birthday) {
  const birthDate = new Date(birthday);
  const ageDifMs = Date.now() - birthDate.getTime();
  const ageDate = new Date(ageDifMs);
  return Math.abs(ageDate.getUTCFullYear() - 1970);
}

// Route to get patient information
router.get('/patient-info', (req, res) => {
  const doctorEmail = req.query.doctorEmail; // Get doctorEmail from query parameters

  if (!doctorEmail) {
    return res.status(400).json({ error: 'Doctor email is required' });
  }

  const query = `
    SELECT DISTINCT u.email, u.name, u.image, pi.birthday, pi.work
    FROM medical_reports mr
    JOIN users u ON mr.user_email = u.email
    JOIN personal_info pi ON mr.user_email = pi.user_email
    WHERE mr.doctor_email = ?
  `;

  db.query(query, [doctorEmail], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    const patients = results.map((row) => {
      const age = calculateAge(row.birthday);
      let imageBase64 = null;
      if (row.image) {
        imageBase64 = Buffer.from(row.image).toString('base64');
      }
      return {
        email: row.email,
        name: row.name,
        image: imageBase64,
        age: age,
        work: row.work
      };
    });

    res.json(patients);
  });
});

// Route to get additional patient details
router.get('/patientdetails', (req, res) => {
  const email = req.query.email;

  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  const query = `
    SELECT gender, weight, height, blood_type
    FROM personal_info
    WHERE user_email = ?
  `;

  db.query(query, [email], (err, results) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'Patient not found' });
    }

    const patientDetails = results[0];
    patientDetails.email = email;

    res.json(patientDetails);
  });
});


module.exports = router;

