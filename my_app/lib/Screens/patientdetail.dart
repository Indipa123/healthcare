import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/contact.dart';
import 'dart:convert';
import 'package:my_app/Screens/patienthistory.dart';

class PatientDetailScreen extends StatefulWidget {
  final String email;
  final String name;
  final String work;
  final int age;
  final String? imageBase64;

  const PatientDetailScreen({
    super.key,
    required this.email,
    required this.name,
    required this.work,
    required this.age,
    this.imageBase64,
  });

  factory PatientDetailScreen.fromJson(Map<String, dynamic> json) {
    return PatientDetailScreen(
      email: json['email'],
      name: json['name'],
      age: json['age'],
      work: json['work'],
      imageBase64: json['image'],
    );
  }

  @override
  _PatientDetailScreenState createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late Future<Map<String, dynamic>> futurePatientDetails;

  @override
  void initState() {
    super.initState();
    futurePatientDetails = fetchPatientDetails(widget.email);
  }

  Future<Map<String, dynamic>> fetchPatientDetails(String email) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/users/patientdetails?email=$email'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load patient details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Patient Detail',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: futurePatientDetails,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('No patient details found'));
            } else {
              final patientDetails = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: widget.imageBase64 != null
                                ? MemoryImage(base64Decode(widget.imageBase64!))
                                : const AssetImage(
                                        'assets/avatar_placeholder.png')
                                    as ImageProvider,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _DetailItem(
                                  label: 'Age', value: '${widget.age} Years'),
                              _DetailItem(label: 'Work', value: widget.work),
                              _DetailItem(
                                  label: 'Gender',
                                  value: patientDetails['gender']),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _DetailItem(
                                  label: 'Weight',
                                  value: '${patientDetails['weight']} kg'),
                              _DetailItem(
                                  label: 'Height',
                                  value: '${patientDetails['height']} cm'),
                              _DetailItem(
                                  label: 'Blood Group',
                                  value: patientDetails['blood_type']),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(
                        label: 'Patient History',
                        icon: Icons.assignment,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientHistoryScreen(
                                email: widget.email,
                                name: widget.name,
                                age: widget.age, // Pass the correct email
                                gender: patientDetails['gender'],
                                imageBase64: widget.imageBase64,
                              ),
                            ),
                          );
                        },
                      ),
                      _ActionButton(
                        label: 'Contact Patient',
                        icon: Icons.contact_phone,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContactPatientScreen(
                                email: widget.email,
                                name: widget.name, // Pass the correct email
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }
}
