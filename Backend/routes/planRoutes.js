const express = require('express');
const router = express.Router();
const db = require('../config/db');

router.get('/plan', (req, res) => {
    const query = 'SELECT name, price, frequency FROM plan';

    db.query(query, (err, results) => {
        if (err) {
            console.error('Error fetching plans:', err.message);
            return res.status(500).json({ error: 'Failed to fetch plans' });
        }

        // Map over the results to ensure proper response formatting
        const plans = results.map(plan => ({
            name: plan.name,
            price: plan.price,
            frequency: plan.frequency,
        }));

        res.status(200).json(plans); // Return the formatted plans
    });
});

router.get('/plan/details/:name', (req, res) => {
    const { name } = req.params;

    const query = `
        SELECT name, price, frequency, features
        FROM plan 
        WHERE name = ?
    `;

    db.query(query, [name], (err, results) => {
        if (err) {
            console.error('Error fetching plan details:', err.message);
            return res.status(500).json({ error: 'Failed to fetch plan details' });
        }

        if (results.length === 0) {
            return res.status(404).json({ error: 'Plan not found' });
        }

        const plan = results[0];
        const price = parseFloat(plan.price); // Ensure price is a number

        res.status(200).json({
            name: plan.name,
            price: plan.price,
            frequency: plan.frequency,
            features: plan.features,
            total: price.toFixed(2), // Total price (same as price since tax is removed)
        });
    });
});


  


module.exports = router;