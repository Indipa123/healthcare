import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/doctorhome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ContactPatientScreen extends StatefulWidget {
  final String email;
  final String name;

  const ContactPatientScreen({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  _ContactPatientScreenState createState() => _ContactPatientScreenState();
}

class _ContactPatientScreenState extends State<ContactPatientScreen> {
  final TextEditingController _messageController = TextEditingController();

  Future<Map<String, dynamic>> fetchPatientContactDetails(String email) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/users/contactdetails?email=$email'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load patient contact details');
    }
  }

  Future<void> sendMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final doctorEmail = prefs.getString('doctorEmail');

    if (doctorEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor email not found')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/api/auth/sendmessage'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_email': widget.email,
        'doctor_email': doctorEmail,
        'message': _messageController.text,
      }),
    );

    if (response.statusCode == 200) {
      _messageController.clear();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Message Sent'),
            content: const Text('Your message has been sent successfully.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Back to Home'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorHomeScreen(),
                    ),
                  ); // Close the dialog
                  // Navigate back to the previous screen
                },
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Contact Patient",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPatientContactDetails(widget.email),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No contact details found'));
          } else {
            final contactDetails = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Patient Name:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contactDetails['name'] ?? 'Unknown Name',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Patient Email:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contactDetails['email'] ?? 'Unknown Email',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Patient Phone:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contactDetails['Contact']?.toString() ?? 'Unknown Phone',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Message:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Enter your message",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text("Send Message"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
}
