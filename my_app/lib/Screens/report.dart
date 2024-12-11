import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/home.dart';
import 'package:my_app/Screens/ureportdetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int _selectedIndex = 1; // Default selected index
  List<dynamic> _reports = []; // Store fetched reports
  bool _isLoading = true; // Show loading state
  String? userEmail; // Store user email

  @override
  void initState() {
    super.initState();
    _loadUserEmail(); // Load email and fetch reports
  }

  // Load user email from SharedPreferences
  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail'); // Key for email
    });
    if (userEmail != null) {
      _fetchReports();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fetch reports from the backend
  Future<void> _fetchReports() async {
    final uri = Uri.parse('http://10.0.2.2:3000/api/users/reports/latest')
        .replace(queryParameters: {'user_email': userEmail!});

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          _reports = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load reports');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching reports: $error');
    }
  }

  void _onReportTapped(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UReportDetailsScreen(reportId: reportId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 35.0), // Added top padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoCard(
                    label: "Heart rate",
                    value: "97 bpm",
                    icon: Icons.favorite,
                    color: Colors.blue.shade100,
                    iconColor: Colors.red,
                  ),
                  _buildInfoCard(
                    label: "B Group",
                    value: "A+",
                    icon: Icons.bloodtype,
                    color: Colors.pink.shade100,
                    iconColor: Colors.pink,
                  ),
                  _buildInfoCard(
                    label: "Weight",
                    value: "103 lbs",
                    icon: Icons.fitness_center,
                    color: Colors.amber.shade100,
                    iconColor: Colors.amber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Latest Report Feedback",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reports.isNotEmpty
                    ? Column(
                        children: _reports.map((report) {
                          return GestureDetector(
                            onTap: () => _onReportTapped(
                                report['id'].toString()), // <-- Here
                            child: _buildReportCard(
                              title: report['report_type'] ?? 'Unknown Report',
                              date: report['created_at'] ?? 'Unknown Date',
                              status: report['status'] ?? 'Unknown Status',
                            ),
                          );
                        }).toList(),
                      )
                    : const Text('No reports available.'),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: "Reports"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation logic
    switch (_selectedIndex) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        break; // Stay on Reports screen
      case 2:
        // Navigate to Cart screen
        break;
      case 3:
        // Navigate to Profile screen
        break;
    }
  }

  // Helper widget to build each report card
  Widget _buildReportCard({
    required String title,
    required String date,
    required String status,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.description, color: Colors.blue.shade200, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: status == "Pending..." ? Colors.grey : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.only(
          top: 16,
          left: 12,
          right: 12,
          bottom: 12), // Adjusted padding for better spacing
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
