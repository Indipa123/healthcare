import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/chooseplan.dart';
import 'package:my_app/Screens/medicalreport.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/Screens/topdoctors.dart';

class DoctorDetailScreen extends StatefulWidget {
  final String email; // Doctor's email

  const DoctorDetailScreen({super.key, required this.email});

  @override
  _DoctorDetailScreenState createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  Map<String, dynamic>? doctorDetails;
  bool isLoading = true;
  String? userEmail; // User's email retrieved from SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadUserEmail(); // Load the user's email from SharedPreferences
  }

  /// Loads the user's email from SharedPreferences
  Future<void> _loadUserEmail() async {
    fetchDoctorDetails();
  }

  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail'); // Return the email
  }

  /// Fetches doctor details from the backend
  Future<void> fetchDoctorDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/api/auth/doctor/details/${widget.email}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          doctorDetails = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print('Failed to load doctor details: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching doctor details: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> checkUserPlan() async {
    final email = await getUserEmail(); // Retrieve the email

    if (email == null || email.isEmpty) {
      print('Email not found in SharedPreferences');
      return;
    }

    final url = Uri.parse('http://10.0.2.2:3000/api/users/user/check-plan');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'email': email, // Send the email to the backend
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Navigate to MedicalReportScreen on success
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const Medicalreport(), // Replace with your actual screen
          ),
        );
      } else if (response.statusCode == 403 || response.statusCode == 404) {
        // Navigate to ChoosePlanScreen on error
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const ChoosePlanScreen(), // Replace with your actual screen
          ),
        );
      } else {
        print('Error: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      print('Error making API request: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorListScreen(),
              ),
            );
          },
        ),
        title: const Text(
          "Doctor Detail",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : doctorDetails == null
              ? const Center(child: Text('Doctor details not found'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor Info
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: doctorDetails!['image'] != null
                                  ? Image.memory(
                                      base64Decode(doctorDetails!['image']),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/doctor.png',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctorDetails!['name'],
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  doctorDetails!['specialty'],
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.blue, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      doctorDetails!['rating'].toString(),
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // About Section
                        const Text(
                          "About",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          doctorDetails!['description'] ??
                              'No description provided',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Reviews Section
                        const Text(
                          "Reviews",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(doctorDetails!['reviews'].length,
                            (index) {
                          final review = doctorDetails!['reviews'][index];
                          return _buildReview(
                            review['username'] ?? 'Unknown',
                            review['date'] ?? 'Unknown date',
                            review['comment'] ?? 'No comment',
                          );
                        }),
                        const SizedBox(height: 24),

                        // Send Medical Report Button
                        Center(
                          child: ElevatedButton(
                            onPressed: checkUserPlan,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                            ),
                            child: const Text(
                              "Send Medical Report",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildReview(String user, String date, String comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
