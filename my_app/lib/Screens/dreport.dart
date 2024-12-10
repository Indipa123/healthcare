import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/doctorhome.dart';
import 'package:my_app/Screens/reportdetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DReportsPage extends StatefulWidget {
  const DReportsPage({super.key});

  @override
  _DReportsPageState createState() => _DReportsPageState();
}

class _DReportsPageState extends State<DReportsPage> {
  int _selectedIndex = 1;
  List<dynamic> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? doctorEmail = prefs.getString('doctorEmail');

      if (doctorEmail != null) {
        final response = await http.get(
          Uri.parse(
              'http://10.0.2.2:3000/api/auth/reports?doctor_email=$doctorEmail'),
        );

        if (response.statusCode == 200) {
          List<dynamic> fetchedReports = json.decode(response.body);

          // Sort the reports by submission date in descending order
          fetchedReports.sort((a, b) {
            DateTime dateA = DateTime.parse(a['createdAt']);
            DateTime dateB = DateTime.parse(b['createdAt']);
            return dateB.compareTo(dateA); // Descending order
          });
          setState(() {
            reports = fetchedReports;
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load reports');
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching reports: $e');
    }
  }

  void _onReportTapped(String reportId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ReportDetailsScreen(reportId: reportId.toString()),
      ),
    );
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? doctorEmail = prefs.getString('doctorEmail');

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorHomeScreen(email: doctorEmail),
          ),
        );
        break;
      case 2:
        // Add navigation to the Cart page here
        break;
      case 3:
        // Add navigation to the Profile page here
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        title: const Text("Reports", style: TextStyle(color: Colors.black)),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? const Center(child: Text("No New reports available"))
              : ListView.builder(
                  itemCount: reports.length,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return GestureDetector(
                      onTap: () => _onReportTapped(report['id'].toString()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  report['reportType'] ?? "Unknown",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Submitted: ${report['createdAt'] ?? 'Unknown'}",
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color:
                                          Color.fromARGB(255, 141, 141, 141)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
