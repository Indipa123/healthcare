import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/chooseplan.dart';
import 'package:my_app/Screens/dprofile.dart';
import 'package:my_app/Screens/dreport.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key, String? email});

  @override
  _DoctorHomeScreenState createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String? doctorName;
  String? doctorEmail;
  int _selectedIndex = 0;
  ImageProvider? profileImageProvider;

  // Load doctor name from shared preferences
  Future<void> _loadDoctorName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      doctorName = prefs.getString('doctorName') ?? 'Doctor';
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData().then((_) {
      _fetchProfileImage();
    });
  }

  Future<void> _fetchProfileImage() async {
    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:3000/api/auth/doctor/image?email=$doctorEmail'),
    );

    if (response.statusCode == 200) {
      setState(() {
        profileImageProvider =
            MemoryImage(response.bodyBytes); // Use binary data directly
      });
    } else {
      print("Failed to load image.");
    }
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      doctorName = prefs.getString('doctorName') ?? 'Doctor Name';
      doctorEmail = prefs.getString('doctorEmail') ?? 'user@example.com';
    });
  }

  // Bottom navigation bar tap handler
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (_selectedIndex) {
      case 0:
        // Stay on the Reports screen (current screen)
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DReportsPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChoosePlanScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profilepage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Welcome Section with Doctor Image
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: profileImageProvider ??
                        const NetworkImage(
                            'https://www.example.com/profile-image.jpg'),
                    radius: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome, Dr. ${doctorName ?? 'Doctor'}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Text(
                          "How is it going today?",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/Doc.png',
                    width: 180,
                    height: 200,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: "Search patients, drugs, articles...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Actions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.person_search,
                    label: "Patients",
                    onTap: () {
                      // Add functionality to navigate to patients list
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.local_pharmacy,
                    label: "Pharmacy",
                    onTap: () {
                      // Add functionality to view or upload medical reports
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Health Articles Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Latest Articles",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to full articles list
                    },
                    child: const Text(
                      "See all",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              _buildArticleCard(
                imagePath: 'assets/images/article1.png',
                title: "Understanding Diabetes: Tips for Management",
                date: "Oct 1, 2023",
                readTime: "6 min read",
              ),
              _buildArticleCard(
                imagePath: 'assets/images/article2.png',
                title: "Top Benefits of Regular Health Check-Ups",
                date: "Sep 25, 2023",
                readTime: "5 min read",
              ),
              _buildArticleCard(
                imagePath: 'assets/images/article3.png',
                title: "Healthy Diet: Foods to Boost Immunity",
                date: "Sep 10, 2023",
                readTime: "4 min read",
              ),
              const SizedBox(height: 20), // Adds extra space at the bottom
            ],
          ),
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

  // Action Button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blue.shade100,
            child: Icon(icon, color: Colors.blue, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.black)),
        ],
      ),
    );
  }

  // Article Card
  Widget _buildArticleCard({
    required String imagePath,
    required String title,
    required String date,
    required String readTime,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$date     $readTime",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.bookmark_border, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}
