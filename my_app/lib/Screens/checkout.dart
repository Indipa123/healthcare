import 'package:flutter/material.dart';
import 'package:my_app/Models/cart_item.dart';
import 'package:my_app/Screens/cart.dart';

class CheckoutScreen extends StatelessWidget {
  final double subtotal;
  final List<CartItem> items;

  const CheckoutScreen(
      {super.key, required this.subtotal, required this.items});

  @override
  Widget build(BuildContext context) {
    final taxes = subtotal * 0.02;
    final total = subtotal + taxes;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CartPage(),
              ),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Details Section
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ...items
                      .map((item) => Text('${item.name} x${item.quantity}')),
                  const SizedBox(height: 10),
                  Text(
                    'Subtotal: Rs. ${subtotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Taxes: Rs. ${taxes.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Divider(thickness: 1),
                  Text(
                    'Total: Rs. ${total.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Saved Payment Methods
            Text(
              'Other Saved Method(s)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/visa_icon.png', // Replace with your Visa icon asset
                    height: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '**** **** **** 9996',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  Radio(
                    value: 'saved_card',
                    groupValue: 'paymentMethod',
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Payment Methods Section
            Text(
              'Payment Methods',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.credit_card, color: Colors.blue),
              title: const Text('Credit/Debit Card'),
              trailing: Radio(
                value: 'card',
                groupValue: 'paymentMethod',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.money, color: Colors.green),
              title: const Text('Cash On Delivery'),
              trailing: Radio(
                value: 'cod',
                groupValue: 'paymentMethod',
                onChanged: (value) {},
              ),
            ),
            const Spacer(),

            // Pay Now Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Implement your payment action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50.0, vertical: 12.0),
                ),
                child: const Text(
                  'Pay Now',
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
