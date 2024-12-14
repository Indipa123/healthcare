import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ViewMessagesScreen extends StatefulWidget {
  const ViewMessagesScreen({super.key});

  @override
  _ViewMessagesScreenState createState() => _ViewMessagesScreenState();
}

class _ViewMessagesScreenState extends State<ViewMessagesScreen> {
  late Future<List<Map<String, dynamic>>> futureMessages;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail');
      if (userEmail != null) {
        futureMessages = fetchMessages(userEmail!);
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String email) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/users/messages?user_email=$email'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> messagesJson = json.decode(response.body);
      return messagesJson.map((json) => json as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load messages');
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
          "View Messages",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: userEmail == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: futureMessages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages found'));
                } else {
                  final messages = snapshot.data!;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ListTile(
                        title: Text(message['doctor_name']),
                        subtitle: Text(message['message']),
                      );
                    },
                  );
                }
              },
            ),
    );
  }
}
