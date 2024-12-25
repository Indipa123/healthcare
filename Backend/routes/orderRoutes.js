const express = require('express');
const router = express.Router();
const db = require('../config/db');


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


module.exports = router;