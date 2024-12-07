import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/articledetails.dart';
import 'package:my_app/Screens/chooseplan.dart';
import 'package:my_app/Screens/profile.dart';
import 'package:my_app/Screens/report.dart';
import 'package:my_app/Screens/topdoctors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/Screens/signin.dart'; // Import the SignInScreen for logout

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userName;
  String? userEmail;
  ImageProvider? profileImageProvider;
  int _selectedIndex = 0;

  // Load doctor name from shared preferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Ruchita';
      userEmail = prefs.getString('userEmail') ?? 'user@example.com';
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
      Uri.parse('http://192.168.8.195:3000/api/users/user/image?email=$userEmail'),
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Implement navigation logic based on index if necessary
    // Example: Navigate to different screens for each index
    switch (_selectedIndex) {
      case 0:
        // Stay on the Reports screen (current screen)
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ReportPage()),
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
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        break;
    }
  }

  // Log out function
  Future<void> _logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all the saved data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
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
                          "Welcome, Mr. ${userName ?? 'User'}",
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
                    hintText: "Search doctor, drugs, articles...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.medical_services,
                    label: "Top Doctors",
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DoctorListScreen()),
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.local_pharmacy,
                    label: "Pharmacy",
                    onTap: () {
                      // Add functionality to navigate to patients list
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.local_hospital,
                    label: "Ambulance",
                    onTap: () {
                      // Add functionality to navigate to patients list
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Health Article Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Health Articles",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See all",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              _buildArticleCard(
                imagePath: 'assets/images/article1.png',
                title:
                    "The 25 Healthiest Fruits You Can Eat, According to a Nutritionist",
                date: "Jun 10, 2023",
                readTime: "5min read",
              ),
              _buildArticleCard(
                imagePath: 'assets/images/article2.png',
                title: "The Impact of COVID-19 on Healthcare Systems",
                date: "Jul 10, 2023",
                readTime: "5min read",
              ),
              _buildArticleCard(
                imagePath: 'assets/images/article3.png',
                title: "The Impact of COVID-19 on Healthcare Systems",
                date: "Jul 10, 2023",
                readTime: "5min read",
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

// Article Card with onTap to navigate to ArticleDetailPage
  Widget _buildArticleCard({
    required String imagePath,
    required String title,
    required String date,
    required String readTime,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailPage(
              imagePath: imagePath,
              title: title,
              date: date,
              readTime: readTime,
            ),
          ),
        );
      },
      child: Card(
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
      ),
    );
  }
}
