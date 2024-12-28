const express = require('express');
const router = express.Router();
const mysql = require('mysql2');
const db = require('../config/db');
const tesseract = require('tesseract.js');

const checkPrescriptionImage = async (imageBuffer) => {
    // Use Tesseract.js to recognize text in the image
    const { data: { text } } = await tesseract.recognize(imageBuffer, 'eng');

    // Return true if the image contains any text, otherwise return false
    return text.trim().length > 0;
};

router.post('/pres/upload', async (req, res) => {
    const { user_email, pres_image, notes, doctor_name } = req.body;
    const date = new Date().toISOString().split('T')[0]; // Current date

    if (!user_email || !pres_image) {
        return res.status(400).json({ error: 'User email and prescription image are required' });
    }

    // Check if the prescription image is valid
    const imageBuffer = Buffer.from(pres_image, 'base64');
    const isValidImage = await checkPrescriptionImage(imageBuffer);
    if (!isValidImage) {
        return res.status(400).json({ error: 'Invalid prescription image' });
    }

    const query = `
        INSERT INTO prescriptions (user_email, pres_image, date, notes, doctor_name)
        VALUES (?, ?, ?, ?, ?)
    `;

    db.query(query, [user_email, imageBuffer, date, notes, doctor_name], (err, result) => {
        if (err) {
            console.error('Error saving prescription:', err);
            return res.status(500).json({ error: 'Failed to save prescription' });
        }

        res.status(201).json({ message: 'Prescription uploaded successfully' });
    });
});




// Get all orders
router.get('/orders', (req, res) => {
    const sql = `
        SELECT o.id, o.user_email, o.total, o.order_status, o.payment_method, o.items, DATE_FORMAT(o.createdAt, '%Y-%m-%d') as createdAt, u.name
        FROM orders o
        LEFT JOIN users u ON o.user_email = u.email
    `;
    
    db.query(sql, (err, results) => {
        if (err) {
            console.error('Error fetching orders:', err);
            return res.status(500).json({ error: 'Error fetching orders' });
        }

        res.json(results);
    });
});



router.post('/orders/create', (req, res) => {
    const { user_email, total, payment_method, items } = req.body;

    if (!user_email || !total || !payment_method || !items) {
        return res.status(400).send('All fields are required');
    }

    const sql = 'INSERT INTO orders (user_email, total, order_status, payment_method, items) VALUES (?, ?, "pending", ?, ?)';
    db.query(sql, [user_email, total, payment_method, items], (err, result) => {
        if (err) {
            console.error('Error creating order:', err);
            return res.status(500).send('Error creating order');
        }
        res.status(201).send('Order created successfully');
    });
});

// Delete order
router.delete('/orders/:id', (req, res) => {
    const { id } = req.params;
    const sql = 'DELETE FROM orders WHERE id = ?';
    db.query(sql, [id], (err, result) => {
        if (err) {
            console.error('Error deleting order:', err);
            return res.status(500).send('Error deleting order');
        }
        res.status(200).send('Order deleted successfully');
    });
});

// Update order
router.put('/orders/:id', (req, res) => {
    const { id } = req.params;
    const { user_email, total, order_status, payment_method, items } = req.body;

    if (!user_email || !total || !order_status || !payment_method || !items) {
        return res.status(400).send('All fields are required');
    }

    const sql = 'UPDATE orders SET user_email = ?, total = ?, order_status = ?, payment_method = ?, items = ? WHERE id = ?';
    db.query(sql, [user_email, total, order_status, payment_method, items, id], (err, result) => {
        if (err) {
            console.error('Error updating order:', err);
            return res.status(500).send('Error updating order');
        }
        res.status(200).send('Order updated successfully');
    });
});


// Get all prescriptions
router.get('/pres', (req, res) => {
    const sql = `
      SELECT p.id, p.user_email, p.pres_image, p.doctor_name, p.notes, DATE_FORMAT(p.date, '%Y-%m-%d') as date, p.pres_status, u.name
      FROM prescriptions p
      LEFT JOIN users u ON p.user_email = u.email
    `;
  
    db.query(sql, (err, results) => {
      if (err) {
        console.error('Error fetching prescriptions:', err);
        return res.status(500).json({ error: 'Error fetching prescriptions' });
      }
  
      // Format results using Array.map()
      const formattedResults = results.map(order => {
        return {
          ...order,
          pres_image: Buffer.isBuffer(order.pres_image) ? order.pres_image.toString('base64') : null
        };
      });
  
      res.json(formattedResults);
    });
});

// Edit prescription order
router.put('/pres/:id', (req, res) => {
    const { id } = req.params;
    const { pres_status } = req.body;

    if (!pres_status) {
        return res.status(400).send('Prescription status is required');
    }

    const sql = 'UPDATE prescriptions SET pres_status = ? WHERE id = ?';
    db.query(sql, [pres_status, id], (err, result) => {
        if (err) {
            console.error('Error updating prescription order:', err);
            return res.status(500).send('Error updating prescription order');
        }
        res.status(200).send('Prescription order updated successfully');
    });
});

// Delete prescription order
router.delete('/pres/:id', (req, res) => {
    const { id } = req.params;
    const sql = 'DELETE FROM prescriptions WHERE id = ?';
    db.query(sql, [id], (err, result) => {
        if (err) {
            console.error('Error deleting prescription order:', err);
            return res.status(500).send('Error deleting prescription order');
        }
        res.status(200).send('Prescription order deleted successfully');
    });
});

// Create a new order and update the prescription order
// Create a new order and update the prescription order
router.post('/presorders/create', (req, res) => {
    const { pres_id, user_email, medications, total } = req.body;

    if (!pres_id || !user_email || !medications || !total) {
        return res.status(400).send('All fields are required');
    }

    const createOrderSql = 'INSERT INTO presorders (pres_id, user_email, medications, total) VALUES (?, ?, ?, ?)';
    const updatePrescriptionSql = 'UPDATE prescriptions SET pres_status = "processed" WHERE id = ?';

    db.query(createOrderSql, [pres_id, user_email, medications, total], (err, result) => {
        if (err) {
            console.error('Error creating order:', err);
            return res.status(500).send('Error creating order');
        }

        db.query(updatePrescriptionSql, [pres_id], (err, result) => {
            if (err) {
                console.error('Error updating prescription order:', err);
                return res.status(500).send('Error updating prescription order');
            }

            res.status(201).send('Order created and prescription order updated successfully');
        });
    });
});

router.get('/pres/orders', (req, res) => {
    const { user_email } = req.query;

    if (!user_email) {
        return res.status(400).json({ error: 'User email is required' });
    }

    const query = `
        SELECT id, DATE_FORMAT(date, '%d-%m-%Y') as date, pres_status
        FROM prescriptions
        WHERE user_email = ?
        ORDER BY date DESC
    `;

    db.query(query, [user_email], (err, results) => {
        if (err) {
            console.error('Error fetching orders:', err);
            return res.status(500).json({ error: 'Failed to fetch orders' });
        }

        res.status(200).json(results);
    });
});

router.get('/pres/order-details', (req, res) => {
    const { user_email, pres_id } = req.query;

    if (!user_email || !pres_id) {
        return res.status(400).json({ error: 'User email and prescription ID are required' });
    }

    const query = `
        SELECT medications, total
        FROM presorders
        WHERE user_email = ? AND pres_id = ?
    `;

    db.query(query, [user_email, pres_id], (err, results) => {
        if (err) {
            console.error('Error fetching order details:', err);
            return res.status(500).json({ error: 'Failed to fetch order details' });
        }

        if (results.length === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }

        res.status(200).json(results[0]);
    });
});


// Route to delete a prescription
/*router.delete('/pres/:presId', (req, res) => {
    const { presId } = req.params;
    const { user_email } = req.query;
  
    const presIdNumeric = parseInt(presId, 10);
    if (isNaN(presIdNumeric)) {
      return res.status(400).json({ error: 'Invalid prescription ID' });
    }
  
    if (!user_email) {
      return res.status(400).json({ error: 'User email is required' });
    }
  
    db.getConnection((err, connection) => {
      if (err) {
        console.error('Error getting database connection:', err);
        return res.status(500).json({ error: 'Database connection failed' });
      }
  
      connection.beginTransaction((err) => {
        if (err) {
          connection.release();
          console.error('Error starting transaction:', err);
          return res.status(500).json({ error: 'Failed to start transaction' });
        }
  
        const deletePresOrdersQuery = 'DELETE FROM presorders WHERE user_email = ? AND pres_id = ?';
  
        connection.query(deletePresOrdersQuery, [user_email, presIdNumeric], (err) => {
          if (err) {
            return connection.rollback(() => {
              connection.release();
              console.error('Error deleting from presorders:', err);
              res.status(500).json({ error: 'Failed to delete from presorders' });
            });
          }
  
          connection.commit((err) => {
            if (err) {
              return connection.rollback(() => {
                connection.release();
                console.error('Error committing transaction:', err);
                res.status(500).json({ error: 'Failed to commit transaction' });
              });
            }
  
            connection.release();
            res.status(200).json({ message: 'Prescription order deleted successfully' });
          });
        });
      });
    });
  });*/
  
  

  
  

module.exports = router;
