import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:my_app/Screens/orderscreen.dart';
import 'package:my_app/Screens/personalinfo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PresCheckoutScreen extends StatefulWidget {
  final double subtotal;
  final List<String> medications;
  final int presId;

  const PresCheckoutScreen(
      {super.key,
      required this.subtotal,
      required this.medications,
      required this.presId});

  @override
  _PresCheckoutScreenState createState() => _PresCheckoutScreenState();
}

class _PresCheckoutScreenState extends State<PresCheckoutScreen> {
  String? _selectedPaymentMethod;
  String? userName;
  String? userContact;
  String? userAddress;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderNameController =
      TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserContactDetails();
  }

  Future<void> _fetchUserContactDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    if (userEmail == null) return;

    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/users/user-contact?email=$userEmail'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userName = data['name'];
        userContact = data['Contact']?.toString();
        userAddress = data['Address'];
      });
    } else {
      print("Failed to load user contact details.");
    }
  }

  Future<void> _pickAddressFromMap() async {
    LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(),
      ),
    );

    if (pickedLocation != null) {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pickedLocation.latitude,
        pickedLocation.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          userAddress = '${placemark.street}, ${placemark.locality}';
        });
      }
    }
  }

  Future<void> _createOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    if (userEmail == null) return;

    // Format medications as a single string
    String formattedMedications = widget.medications.join(', ');

    final orderDetails = {
      'user_email': userEmail,
      'total': widget.subtotal,
      'payment_method': _selectedPaymentMethod,
      'items': formattedMedications,
    };

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/orders/orders/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(orderDetails),
    );

    if (response.statusCode == 201) {
      // Order created successfully
      print("Order created successfully.");
      _showOrderSuccessDialog();
    } else {
      print("Failed to create order.");
    }
  }

  void _showOrderSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Order placed successfully"),
          content: const Text(
              "Your order placed successfully and you can see the status from your profile View orders Section"),
          actions: <Widget>[
            TextButton(
              child: const Text("View Orders"),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to the orders screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const OrdersScreen(), // Replace with your OrdersScreen
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipping = widget.subtotal * 0.03;
    final total = widget.subtotal + shipping;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Contact Details Section
            Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text('Name: $userName'),
                  Text('Contact: $userContact'),
                  GestureDetector(
                    onTap: _pickAddressFromMap,
                    child: Text(
                      'Address: $userAddress',
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Payment Details Section
            Container(
              margin: const EdgeInsets.only(bottom: 20.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
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
                  ...widget.medications.map((medication) => Text(medication)),
                  const SizedBox(height: 10),
                  Text(
                    'Subtotal: Rs. ${widget.subtotal.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Shipping: Rs. ${shipping.toStringAsFixed(2)}',
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
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value.toString();
                      });
                    },
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
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value.toString();
                  });
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.money, color: Colors.green),
              title: const Text('Cash On Delivery'),
              trailing: Radio(
                value: 'cash on delivery',
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value.toString();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),

            // Card Details Form
            Visibility(
              visible: _selectedPaymentMethod == 'card',
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Card Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            value.length != 16 ||
                            !RegExp(r'^\d{16}$').hasMatch(value)) {
                          return 'Card number must be 16 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: cardHolderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Cardholder Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Cardholder name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiryDateController,
                            decoration: const InputDecoration(
                              labelText: 'Expiry Date (MM/YY)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Expiry date is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: cvvController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.length != 3 ||
                                  !RegExp(r'^\d{3}$').hasMatch(value)) {
                                return 'CVV must be 3 digits';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Pay Now Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedPaymentMethod == 'card' &&
                        _formKey.currentState!.validate()) {
                      _createOrder();
                    } else if (_selectedPaymentMethod == 'cash on delivery') {
                      _createOrder();
                    }
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
            ),
          ],
        ),
      ),
    );
  }
}
