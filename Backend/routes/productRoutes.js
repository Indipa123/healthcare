const express = require('express');
const mysql = require('mysql2');
const router = express.Router();
const db = require('../config/db');

router.post('/add', (req, res) => {
    const { name, category, stock, price, image, size, prescription } = req.body;

    if (!name || !category || !stock || !price || !image || !size || !prescription) {
        return res.status(400).send('All fields are required');
    }

    // Decode base64 to binary
    const base64Data = image.replace(/^data:image\/\w+;base64,/, '');
    const imageBuffer = Buffer.from(base64Data, 'base64');

    const sql = 'INSERT INTO products (name, category, stock, price, image, size, prescription) VALUES (?, ?, ?, ?, ?, ?, ?)';
    db.query(sql, [name, category, stock, price, imageBuffer, size, prescription], (err, result) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Error adding product');
        }
        res.status(201).send('Product added successfully');
    });
});


router.get('/', (req, res) => {
    const sql = 'SELECT * FROM products';
    
    db.query(sql, (err, results) => {
        if (err) {
            console.error('Error fetching products:', err);
            return res.status(500).json({ error: 'Error fetching products' });
        }

        // Convert image buffers to base64 only if the image exists
        const formattedResults = results.map(product => ({
            ...product,
            image: product.image ? product.image.toString('base64') : null
        }));

        res.json(formattedResults);
    });
});

// Delete product
router.delete('/:id', (req, res) => {
    const { id } = req.params;
    const sql = 'DELETE FROM products WHERE id = ?';
    db.query(sql, [id], (err, result) => {
        if (err) {
            console.error('Error deleting product:', err);
            return res.status(500).send('Error deleting product');
        }
        res.status(200).send('Product deleted successfully');
    });
});

router.put('/:id', (req, res) => {
    const { id } = req.params;
    const { name, category, stock, price, image, size, prescription } = req.body;

    if (!name || !category || !stock || !price || !size || !prescription) {
        return res.status(400).send('All fields are required');
    }

    let sql;
    let params;

    if (image) {
        // Decode base64 to binary
        const base64Data = image.replace(/^data:image\/\w+;base64,/, '');
        const imageBuffer = Buffer.from(base64Data, 'base64');
        sql = 'UPDATE products SET name = ?, category = ?, stock = ?, price = ?, image = ?, size = ?, prescription = ? WHERE id = ?';
        params = [name, category, stock, price, imageBuffer, size, prescription, id];
    } else {
        sql = 'UPDATE products SET name = ?, category = ?, stock = ?, price = ?, size = ?, prescription = ? WHERE id = ?';
        params = [name, category, stock, price, size, prescription, id];
    }

    db.query(sql, params, (err, result) => {
        if (err) {
            console.error('Error updating product:', err);
            return res.status(500).send('Error updating product');
        }
        res.status(200).send('Product updated successfully');
    });
});

router.get('/popular', (req, res) => {
    const sql = 'SELECT * FROM products WHERE prescription = "no need"';
    
    db.query(sql, (err, results) => {
        if (err) {
            console.error('Error fetching products:', err);
            return res.status(500).json({ error: 'Error fetching products' });
        }

        // Convert image buffers to base64 only if the image exists
        const formattedResults = results.map(product => ({
            ...product,
            image: product.image ? product.image.toString('base64') : null
        }));

        res.json(formattedResults);
    });
});

router.get('/onsale', (req, res) => {
    const sql = 'SELECT * FROM products WHERE prescription = "need"';
    
    db.query(sql, (err, results) => {
        if (err) {
            console.error('Error fetching products:', err);
            return res.status(500).json({ error: 'Error fetching products' });
        }

        // Convert image buffers to base64 only if the image exists
        const formattedResults = results.map(product => ({
            ...product,
            image: product.image ? product.image.toString('base64') : null
        }));

        res.json(formattedResults);
    });
});

router.post('/cart/add', (req, res) => {
    const { userEmail, productName, productSize, productPrice, productImage, quantity } = req.body;

    // Decode base64 to binary
    const base64Data = productImage.replace(/^data:image\/\w+;base64,/, '');
    const imageBuffer = Buffer.from(base64Data, 'base64');

    // Check if the item already exists in the cart
    const checkSql = 'SELECT * FROM cart WHERE user_email = ? AND product_name = ? AND product_size = ?';
    const checkParams = [userEmail, productName, productSize];

    db.query(checkSql, checkParams, (checkErr, checkResult) => {
        if (checkErr) {
            console.error('Error checking cart:', checkErr);
            return res.status(500).send('Server error');
        }

        if (checkResult.length > 0) {
            // Item exists, update the quantity
            const updateSql = 'UPDATE cart SET quantity = quantity + ? WHERE user_email = ? AND product_name = ? AND product_size = ?';
            const updateParams = [quantity, userEmail, productName, productSize];

            db.query(updateSql, updateParams, (updateErr, updateResult) => {
                if (updateErr) {
                    console.error('Error updating cart:', updateErr);
                    return res.status(500).send('Server error');
                }
                res.status(201).json(updateResult);
            });
        } else {
            // Item does not exist, insert a new record
            const insertSql = 'INSERT INTO cart (user_email, product_name, product_size, product_price, product_image, quantity) VALUES (?, ?, ?, ?, ?, ?)';
            const insertParams = [userEmail, productName, productSize, productPrice, imageBuffer, quantity];

            db.query(insertSql, insertParams, (insertErr, insertResult) => {
                if (insertErr) {
                    console.error('Error adding to cart:', insertErr);
                    return res.status(500).send('Server error');
                }
                res.status(201).json(insertResult);
            });
        }
    });
});

router.get('/cart', (req, res) => {
    const { userEmail } = req.query;
  
    const sql = 'SELECT * FROM cart WHERE user_email = ?';
    db.query(sql, [userEmail], (err, results) => {
        if (err) {
            console.error('Error fetching cart items:', err);
            return res.status(500).send('Server error');
        }
  
        // Convert BLOB image data to base64 string
        const cartItems = results.map(item => ({
            ...item,
            product_image: item.product_image ? item.product_image.toString('base64') : null
        }));
  
        res.status(200).json(cartItems);
    });
});

router.delete('/del/cart', (req, res) => {
    const { userEmail, product_id } = req.query; // Use req.query instead of req.params
  
    const sql = 'DELETE FROM cart WHERE user_email = ? AND id = ?';
    db.query(sql, [userEmail, product_id], (err, results) => {
      if (err) {
        console.error('Error removing cart item:', err);
        return res.status(500).send('Server error');
      }
  
      if (results.affectedRows > 0) {
        res.status(200).send('Item removed from cart');
      } else {
        res.status(404).send('Item not found');
      }
    });
  });
  

  
module.exports = router;