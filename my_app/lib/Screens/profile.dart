import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/Screens/chooseplan.dart';
import 'package:my_app/Screens/home.dart';
import 'package:my_app/Screens/report.dart';
import 'package:my_app/Screens/signin.dart';
import 'package:my_app/Screens/viewmessage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userName;
  String? userEmail;
  int _selectedIndex = 0;
  File? _profileImage;
  ImageProvider? profileImageProvider;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Implement navigation logic based on index if necessary
    // Example: Navigate to different screens for each index
    switch (_selectedIndex) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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
        break;
    }
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
      Uri.parse('http://10.0.2.2:3000/api/users/user/image?email=$userEmail'),
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

  final List<HealthStat> healthStats = [
    HealthStat(icon: Icons.favorite, title: 'Heart rate', value: '215bpm'),
    HealthStat(
        icon: Icons.local_fire_department, title: 'Calories', value: '756cal'),
    HealthStat(icon: Icons.monitor_weight, title: 'Weight', value: '103lbs'),
  ];

  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.favorite_outline, title: 'My Saved'),
    MenuItem(icon: Icons.message, title: 'Messages'),
    MenuItem(icon: Icons.history, title: 'Feedback History'),
    MenuItem(icon: Icons.payment, title: 'Payment Method'),
    MenuItem(icon: Icons.question_answer, title: 'FAQs'),
    MenuItem(icon: Icons.contact_support, title: 'Contact Us'),
    MenuItem(icon: Icons.logout, title: 'Logout'),
  ];

  // Load user data from shared preferences
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Ruchita';
      userEmail = prefs.getString('userEmail') ?? 'user@example.com';
    });
  }

  Future<void> _showImageOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text("Take Photograph"),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_album),
                title: const Text("Select from Album"),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      _uploadProfileImage(_profileImage!);
    }
  }

  Future<void> _uploadProfileImage(File image) async {
    try {
      // Convert image to bytes
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Send to backend
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/users/upload'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": userEmail, "image": base64Image}),
      );

      if (response.statusCode == 200) {
        print("Profile image updated successfully.");
        _fetchProfileImage(); // Refresh profile image from backend
      } else {
        print("Failed to upload image.");
      }
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  // Log out function
  Future<void> _logOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data on logout
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 40.0, 16.0, 0),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _showImageOptions,
                  child: CircleAvatar(
                    backgroundImage: profileImageProvider ??
                        const NetworkImage(
                            'https://www.example.com/profile-image.jpg'),
                    radius: 36,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    userName ?? 'User',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Flag_of_Sri_Lanka.svg/800px-Flag_of_Sri_Lanka.svg.png'),
                  radius: 14,
                ),
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.black),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Health Stats Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: healthStats.map((stat) {
                return Column(
                  children: [
                    Icon(stat.icon, color: Colors.blue, size: 28),
                    const SizedBox(height: 4),
                    Text(stat.title, style: const TextStyle(fontSize: 16)),
                    Text(stat.value,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Menu Options Section
            Expanded(
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(menuItems[index].icon, color: Colors.blue),
                    ),
                    title: Text(menuItems[index].title,
                        style: const TextStyle(fontSize: 16)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      if (menuItems[index].title == 'Logout') {
                        _logOut();
                      } else if (menuItems[index].title == 'Messages') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ViewMessagesScreen(),
                          ),
                        );
                      } else {
                        // Handle other menu options
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
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
}

class HealthStat {
  final IconData icon;
  final String title;
  final String value;

  HealthStat({required this.icon, required this.title, required this.value});
}

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}
