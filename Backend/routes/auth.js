const express = require('express');
const router = express.Router();
const db = require('../config/db');


// Update profile image
router.post('/upload', (req, res) => {
  const { email, image } = req.body;
  const query = 'UPDATE doctors SET image = ? WHERE email = ?';
  db.query(query, [Buffer.from(image, 'base64'), email], (err, result) => {
      if (err) return res.status(500).json({ error: err.message });
      res.status(200).json({ message: 'Image updated successfully' });
  });
});


// Sign up
router.post('/signup', (req, res) => {
    const { name, specialty, password, licenseNumber, email } = req.body;
    const query = 'INSERT INTO doctors (name, specialty, password, licenseNumber, email) VALUES (?, ?, ?, ?, ?)';
    db.query(query, [name, specialty, password, licenseNumber, email], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ message: 'User registered successfully' });
    });
});

// Login
router.post('/login', (req, res) => {
    const { email, password } = req.body;
    const query = 'SELECT * FROM doctors WHERE email = ? AND password = ?';
    db.query(query, [email, password], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        if (results.length === 0) {
            return res.status(400).json({ error: 'Invalid email or password' });
        }
        
        const user = results[0];
        res.status(200).json({ message: 'Login successful', user: { id: user.id, name: user.name, specialty: user.specialty, email: user.email } });
    });
});


router.get('/doctor/image', (req, res) => {
    const { email } = req.query;
    const query = 'SELECT image FROM doctors WHERE email = ?';
  
    db.query(query, [email], (err, results) => {
      if (err) return res.status(500).json({ error: err.message });
  
      if (results.length > 0 && results[0].image) {
        const imageBuffer = results[0].image;
  
        // Set headers for content type and disposition to trigger download
        res.setHeader('Content-Type', 'image/jpeg'); // or 'image/png' depending on the image format
        res.setHeader('Content-Disposition', 'attachment; filename="doctor-image.jpg"'); // Customize file name and extension as needed
        res.status(200).send(imageBuffer);
      } else {
        res.status(404).json({ message: 'Image not found' });
      }
    });
  });
  
router.get('/doctor/details', (req, res) => {
    const query = 'SELECT email, name, specialty, image FROM doctors';

    db.query(query, (err, results) => {
        if (err) return res.status(500).json({ error: err.message });

        const doctors = results.map(doctor => {
            if (doctor.image) {
                doctor.image = Buffer.from(doctor.image).toString('base64'); // Convert BLOB to base64
            }
            return {
                email: doctor.email,
                name: doctor.name,
                specialty: doctor.specialty,
                image: doctor.image || null, // Send null if no image is present
            };
        });

        res.status(200).json(doctors);
    });
});

router.get('/doctor/details/:email', (req, res) => {
  const email = req.params.email;
  const query = `
    SELECT name, specialty, image, description, rating 
    FROM doctors 
    WHERE email = ?;
  `;
  const reviewsQuery = `
    SELECT username, comment, DATE_FORMAT(date, '%Y-%m-%d') as date 
    FROM reviews 
    WHERE doctor_email = ?;
  `;

  db.query(query, [email], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });

    if (results.length === 0) {
      return res.status(404).json({ error: 'Doctor not found' });
    }

    const doctor = results[0];
    if (doctor.image) {
      doctor.image = Buffer.from(doctor.image).toString('base64');
    }

    db.query(reviewsQuery, [email], (err, reviewResults) => {
      if (err) return res.status(500).json({ error: err.message });

      res.status(200).json({
        ...doctor,
        reviews: reviewResults,
      });
    });
  });
});

router.get('/report/:id', (req, res) => {
  const reportId = req.params.id;

  const query = `
    SELECT id, report_type, user_email, doctor_email, file_data, DATE_FORMAT(created_at, '%Y-%m-%d') as created_at 
    FROM medical_reports 
    WHERE id = ?;
  `;

  db.query(query, [reportId], (err, results) => {
    if (err) return res.status(500).json({ error: err.message });

    if (results.length === 0) {
      return res.status(404).json({ error: 'Report not found' });
    }

    const report = results[0];
    if (report.file_data) {
      report.fileData = Buffer.from(report.file_data).toString('base64');
    }

    res.status(200).json(report);
  });
});


router.get('/reports', (req, res) => {
  const { doctor_email } = req.query;

  const query = `
      SELECT id, report_type, user_email, doctor_email, DATE_FORMAT(created_at, '%Y-%m-%d') as created_at 
      FROM medical_reports  
      WHERE doctor_email = ? AND status != 'View Report Feedback'
  `;

  db.query(query, [doctor_email], (err, results) => {
      if (err) return res.status(500).json({ error: err.message });

      const reports = results.map(report => ({
          id: report.id,
          reportType: report.report_type,
          createdAt: report.created_at,
          userEmail: report.user_email, // Include user_email if you want it in the response
          doctorEmail: report.doctor_email // Include doctor_email if you want it in the response
      }));

      res.status(200).json(reports);
  });
});


router.post('/report/feedback', (req, res) => {
  const {
    report_id,
    doctor_email,
    user_email,
    prescription_details,
    prescription_image,  // Assuming base64 encoded image
    feedback
  } = req.body;

  // Convert base64 image back to binary data
  let imageBuffer = null;
  if (prescription_image) {
    imageBuffer = Buffer.from(prescription_image, 'base64');
  }

  // SQL query to insert feedback
  const queryFeedback = `
    INSERT INTO feedback (
      report_id, doctor_email, user_email, prescription_details, prescription_image, feedback
    ) VALUES (?, ?, ?, ?, ?, ?)
  `;

  // SQL query to update report status
  const queryUpdateReportStatus = `
    UPDATE medical_reports 
    SET status = 'View Report Feedback'
    WHERE id = ?
  `;

  // Start a transaction to ensure both operations (insert and update) succeed
  db.beginTransaction((err) => {
    if (err) {
      console.error("Transaction error:", err);
      return res.status(500).json({ error: 'Failed to begin transaction' });
    }

    // Insert the feedback
    db.query(queryFeedback, [
      report_id,
      doctor_email,
      user_email,
      prescription_details,
      imageBuffer,
      feedback
    ], (err, results) => {
      if (err) {
        return db.rollback(() => {
          console.error("Error inserting feedback:", err);
          res.status(500).json({ error: err.message });
        });
      }

      // Update the report status
      db.query(queryUpdateReportStatus, [report_id], (err, results) => {
        if (err) {
          return db.rollback(() => {
            console.error("Error updating report status:", err);
            res.status(500).json({ error: err.message });
          });
        }

        // Commit the transaction
        db.commit((err) => {
          if (err) {
            return db.rollback(() => {
              console.error("Error committing transaction:", err);
              res.status(500).json({ error: 'Failed to commit transaction' });
            });
          }

          // Successfully inserted feedback and updated report status
          res.status(201).json({ message: 'Feedback submitted successfully', feedbackId: results.insertId });
        });
      });
    });
  });
});

router.get('/reportsd', (req, res) => {
  const { doctor_email, user_email } = req.query;

  // Validate required query parameters
  if (!doctor_email || !user_email) {
    return res.status(400).json({ error: 'Doctor email and user email are required' });
  }

  console.log('doctor_email:', doctor_email);
  console.log('user_email:', user_email);

  // SQL query to fetch reports
  const query = `
    SELECT id, report_type, user_email, doctor_email, 
           DATE_FORMAT(created_at, '%Y-%m-%d') as created_at 
    FROM medical_reports  
    WHERE doctor_email = ? AND user_email = ?
  `;

  // Execute the query with parameters
  db.query(query, [doctor_email, user_email], (err, results) => {
    if (err) {
      console.error('Database error:', err);
      return res.status(500).json({ error: 'Internal Server Error' });
    }

    console.log('Query results:', results);

    // Ensure only the filtered records are returned
    const reports = results.map(report => ({
      id: report.id,
      reportType: report.report_type,
      createdAt: report.created_at,
      userEmail: report.user_email,
      doctorEmail: report.doctor_email,
    }));

    // Respond with the filtered reports
    res.status(200).json(reports);
  });
});




module.exports = router;
