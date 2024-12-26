import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/Screens/ureportdetail.dart'; // Add this import

class FeedbackHistoryScreen extends StatefulWidget {
  const FeedbackHistoryScreen({super.key});

  @override
  _FeedbackHistoryScreenState createState() => _FeedbackHistoryScreenState();
}

class _FeedbackHistoryScreenState extends State<FeedbackHistoryScreen> {
  List<dynamic> feedbacks = [];
  bool _isLoading = true;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  Future<void> _fetchUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('userEmail');
    setState(() {
      userEmail = email;
    });
    if (email != null) {
      _fetchFeedbacks(email);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFeedbacks(String email) async {
    final uri = Uri.parse('http://10.0.2.2:3000/api/users/reports/feedback')
        .replace(queryParameters: {'user_email': email});

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          feedbacks = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load feedbacks');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching feedbacks: $error');
    }
  }

  void _onFeedbackTapped(String reportId) {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Feedback History',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : feedbacks.isEmpty
              ? const Center(child: Text('No feedbacks found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final feedback = feedbacks[index];
                    return GestureDetector(
                      onTap: () => _onFeedbackTapped(feedback['id'].toString()),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(Icons.description,
                                  color: Colors.blue.shade200, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      feedback['report_type'] ??
                                          'Unknown Report',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      feedback['created_at'] ?? 'Unknown Date',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      feedback['status'] ?? 'Unknown Status',
                                      style: TextStyle(
                                        color:
                                            feedback['status'] == "Pending..."
                                                ? Colors.grey
                                                : Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.more_vert, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
