import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class PlanDetailsScreen extends StatefulWidget {
  final String planName;

  const PlanDetailsScreen({super.key, required this.planName});

  @override
  State<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends State<PlanDetailsScreen> {
  late Future<Map<String, dynamic>> planDetailsFuture;
  String? userEmail; // User's email retrieved from SharedPreferences

  // Payment-related variables
  String selectedPaymentMethod = 'Visa';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController cardHolderNameController =
      TextEditingController();
  final TextEditingController expiryDateController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();

    getUserEmail().then((email) {
      setState(() {
        userEmail = email;
      });
    });

    planDetailsFuture = fetchPlanDetails(widget.planName);
  }

  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail'); // Return the email
  }

  Future<Map<String, dynamic>> fetchPlanDetails(String planName) async {
    final url = 'http://10.0.2.2:3000/api/plan/plan/details/$planName';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Clean up the features array by removing unwanted characters
        final featuresRaw = data['features'];
        final cleanedFeatures = (featuresRaw is List)
            ? featuresRaw
                .map((e) => e.toString().replaceAll('"', '').trim())
                .toList()
            : featuresRaw
                .toString()
                .replaceAll('"', '')
                .replaceAll('[', '')
                .replaceAll(']', '')
                .split(',')
                .map((e) => e.trim())
                .toList();

        data['features'] = cleanedFeatures;
        return data;
      } else {
        throw Exception('Failed to fetch plan details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching plan details: $e');
      throw Exception('Error fetching plan details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: planDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No plan details available'));
          } else {
            final plan = snapshot.data!;
            final features = List<String>.from(plan['features']);
            final subtotal = plan['price'];
            final total = plan['total'];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              plan['name'] ?? 'Plan Details',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            for (final feature in features)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.star_border, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Payment Detail',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('Rs $subtotal'),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rs $total',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: selectedPaymentMethod,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                          value: 'Visa',
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/visa_icon.png', // Replace with the actual path to your Visa icon
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text('Visa'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'MasterCard',
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/mastercard_icon.png', // Replace with the actual path to your MasterCard icon
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 10),
                              const Text('MasterCard'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedPaymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Card Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Form(
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
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  // Handle payment confirmation with userEmail and selected payment method
                                  handlePayment(userEmail, widget.planName,
                                      double.parse(subtotal));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Confirm and Pay',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Handle payment submission logic
  void handlePayment(String? userEmail, String planName, double pricePaid) {
    // Send payment request to the backend
    final paymentData = {
      'userEmail': userEmail,
      'plan_name': planName,
      'price_paid': pricePaid.toString(),
    };

    http
        .post(Uri.parse('http://10.0.2.2:3000/api/users/payment'),
            body: paymentData)
        .then((response) {
      if (response.statusCode == 200) {
        // Successfully processed payment
        print('Payment successful!');
        // Optionally navigate to a confirmation screen or show success message
      } else {
        print('Failed to process payment: ${response.statusCode}');
      }
    }).catchError((e) {
      print('Error: $e');
    });
  }
}
