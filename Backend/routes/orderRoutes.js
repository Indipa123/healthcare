const express = require('express');
const router = express.Router();
const db = require('../config/db');

// Get all orders
router.get('/orders', (req, res) => {
    const sql = `
        SELECT o.id, o.user_email, o.total, o.order_status, o.payment_method, o.items, u.name
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


module.exports = router;