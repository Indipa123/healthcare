import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/dreportdetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PatientHistoryScreen extends StatefulWidget {
  final String email;
  final String name;
  final int age;
  final String gender;
  final String? imageBase64;

  const PatientHistoryScreen({
    super.key,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    this.imageBase64,
  });

  @override
  _PatientHistoryScreenState createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  late Future<List<Map<String, dynamic>>> futureReports;

  @override
  void initState() {
    super.initState();
    futureReports = fetchReports();
  }

  Future<String?> getDoctorEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('doctorEmail');
  }

  Future<List<Map<String, dynamic>>> fetchReports() async {
    final doctorEmail = await getDoctorEmail();
    if (doctorEmail == null) {
      throw Exception('Doctor email not found');
    }

    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:3000/api/auth/reportsd?doctor_email=$doctorEmail&user_email=${widget.email}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> reportsJson = json.decode(response.body);
      return reportsJson.map((json) => json as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load reports');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          color: Colors.black,
        ),
        title: const Text(
          'Patient History',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: widget.imageBase64 != null
                      ? MemoryImage(base64Decode(widget.imageBase64!))
                      : const AssetImage('assets/avatar_placeholder.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age ${widget.age}, ${widget.gender}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Report Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: futureReports,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No reports found'));
                  } else {
                    final reports = snapshot.data!;
                    return ListView.builder(
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                const Icon(Icons.insert_drive_file, size: 32),
                          ),
                          title: Text(
                            report['reportType'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            'Submitted on ${report['createdAt']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey,
                            ),
                          ),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DReportDetailScreen(
                                  reportId: report['id'].toString(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
