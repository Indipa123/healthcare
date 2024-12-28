import 'package:flutter/material.dart';
import 'package:my_app/Screens/prescheckout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderDetailsPage extends StatefulWidget {
  final int presId;

  const OrderDetailsPage({Key? key, required this.presId}) : super(key: key);

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? orderDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userEmail = prefs.getString('userEmail');

    if (userEmail == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final uri = Uri.parse('http://10.0.2.2:3000/api/orders/pres/order-details')
        .replace(queryParameters: {
      'user_email': userEmail,
      'pres_id': widget.presId.toString(),
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          orderDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching order details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetails == null
              ? const Center(child: Text('Order details not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medications:',
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      ...orderDetails!['medications']
                          .split(',')
                          .map<Widget>((medication) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  medication.trim(),
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              ))
                          .toList(),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Order Summary:',
                        style: TextStyle(
                            fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Total: Rs.${double.parse(orderDetails!['total']).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Shipping: Rs.${(double.parse(orderDetails!['total'].toString()) * 0.03).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Full Total: Rs.${(double.parse(orderDetails!['total'].toString()) * 1.03).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16.0),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Promo code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PresCheckoutScreen(
                                subtotal: double.parse(orderDetails!['total']),
                                medications: List<String>.from(
                                    orderDetails!['medications']
                                        .split(',')
                                        .map((med) => med.trim())),
                                presId: widget.presId.toInt(),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue, // Text color
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Place Order'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
