// Import necessary modules
const express = require('express');
const bcrypt = require('bcrypt'); // Add this line to import bcrypt
const app = express();
const cors = require('cors');
const bodyParser = require('body-parser');
const userRoutes = require('./routes/userRoutes');
const authRoutes = require('./routes/auth');
const planRoutes = require('./routes/planRoutes');
const productRoutes = require('./routes/productRoutes');
const orderRoutes = require('./routes/orderRoutes');
const db = require('./config/db');  // To initiate MySQL connection

// Increase the payload limit for JSON data
app.use(cors()); // Enable CORS for all routes
app.use(bodyParser.json({ limit: '10mb' }));  // Adjust '10mb' as needed
app.use(bodyParser.urlencoded({ limit: '10mb', extended: true }));

// Middleware to parse JSON bodies
app.use(express.json());

// Routes
app.use('/api/plan',planRoutes);
app.use('/api/users', userRoutes);
app.use('/api/auth', authRoutes );
app.use('/api/products',productRoutes);
app.use('/api/orders',orderRoutes);


// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});

// Sign-up route
app.post('/api/users', (req, res) => {
  const { name, email, password } = req.body;

  // Hash the password before storing
  const hashedPassword = bcrypt.hashSync(password, 10);
  const userQuery = 'INSERT INTO users (name, email, password) VALUES (?, ?, ?)';
  const personalInfoQuery = 'INSERT INTO personal_info (user_email) VALUES (?)';

  // Start a transaction
  db.beginTransaction((err) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }

    db.query(userQuery, [name, email, hashedPassword], (err, userResults) => {
      if (err) {
        return db.rollback(() => {
          res.status(500).json({ error: 'Database error' });
        });
      }

      db.query(personalInfoQuery, [email], (err, personalInfoResults) => {
        if (err) {
          return db.rollback(() => {
            res.status(500).json({ error: 'Database error' });
          });
        }

        // Commit the transaction
        db.commit((err) => {
          if (err) {
            return db.rollback(() => {
              res.status(500).json({ error: 'Database error' });
            });
          }

          res.status(201).json({ message: 'User created successfully' });
        });
      });
    });
  });
});


// Login route
app.post('/api/login', (req, res) => {
  const { email, password } = req.body;

  const query = 'SELECT * FROM users WHERE email = ?';
  db.query(query, [email], (err, results) => {
    if (err) {
      return res.status(500).json({ error: 'Database error' });
    }

    if (results.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const user = results[0];

    // Compare entered password with stored hash
    bcrypt.compare(password, user.password, (err, isMatch) => {
      if (err) {
        return res.status(500).json({ error: 'Error comparing passwords' });
      }

      if (!isMatch) {
        return res.status(401).json({ error: 'Invalid email or password' });
      }

      res.status(200).json({ message: 'Login successful', user: { id: user.id, name: user.name, email: user.email } });
    });
  });
});
