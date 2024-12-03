const db = require('../config/db');
const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');

// Nodemailer transporter setup
const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true, // Use SSL
  auth: {
    user: 'aidiscord22@gmail.com', // Replace with your email
    pass: 'holonokjqlcfeaxq',  // Replace with your app password
  },
  logger: true,  // Enables logging
  debug: true,   // Enables debugging for the email sending process
});

// Get all users
exports.getAllUsers = (req, res) => {
  const query = 'SELECT * FROM users'; // Modify according to your table
  db.promise().query(query) // Using mysql2's promise API
    .then(([results]) => {
      res.status(200).json(results);
    })
    .catch((err) => {
      console.error('Database query error:', err);
      res.status(500).json({ error: 'Database query error' });
    });
};

// Create a new user
exports.createUser = async (req, res) => {
  const { name, email, password } = req.body;

  try {
    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Insert the new user into the database
    const query = 'INSERT INTO users (name, email, password) VALUES (?, ?, ?)';
    const [results] = await db.promise().query(query, [name, email, hashedPassword]);

    // Send the welcome email
    const mailOptions = {
      from: 'gangodaayomal@gmail.com', // Replace with your email
      to: email,
      subject: 'Welcome to Healthcare App!',
      text: `Hi ${name},\n\nYou have successfully registered into the healthcare app.\n\nThank you for joining us!`,
    };

    // Send the email using Nodemailer
    await transporter.sendMail(mailOptions);

    res.status(201).json({ message: 'User created successfully and email sent!', userId: results.insertId });
  } catch (error) {
    console.log('Error during user creation or email sending:', error);
    res.status(500).json({ error: 'Error creating user or sending email' });
  }
};

exports.loginUser = (req, res) => {
  const { email, password } = req.body;

  const query = 'SELECT * FROM users WHERE email = ?';
  db.promise().query(query, [email])
    .then(([results]) => {
      if (results.length === 0) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      const user = results[0];

      bcrypt.compare(password, user.password, (err, isMatch) => {
        if (err) {
          return res.status(500).json({ error: 'Error comparing passwords' });
        }

        if (!isMatch) {
          return res.status(401).json({ error: 'Invalid email or password' });
        }
        res.status(200).json({ message: 'Login successful', user: { id: user.id, name: user.name, email: user.email } });
      });
    })
    .catch((err) => {
      console.error('Database error:', err);
      res.status(500).json({ error: 'Database error' });
    });
};
