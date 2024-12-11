import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UReportDetailsScreen extends StatefulWidget {
  final String reportId;

  const UReportDetailsScreen({super.key, required this.reportId});

  @override
  _UReportDetailsScreenState createState() => _UReportDetailsScreenState();
}

class _UReportDetailsScreenState extends State<UReportDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _reportDetails;

  @override
  void initState() {
    super.initState();
    // _fetchReportDetails();
  }

  // Fetch report details using the reportId passed
  Future<void> _fetchReportDetails() async {
    final uri =
        Uri.parse('http://10.0.2.2:3000/api/auth/report/${widget.reportId}');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          _reportDetails = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load report details');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching report details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Report Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportDetails != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date Submitted:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _reportDetails!['created_at'] ?? 'Unknown Date',
                        style: const TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      const Text(
                        'Type of Report:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _reportDetails!['report_type'] ?? 'Unknown Type',
                        style: const TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.description, color: Colors.white),
                            SizedBox(width: 8),
                            Text('View Report',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      const Text(
                        'Prescribed Medications:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _reportDetails!['prescription_details'] ??
                            'No medications prescribed',
                        style: const TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.description, color: Colors.white),
                            SizedBox(width: 8),
                            Text('View Prescription',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onPressed: () {},
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.download, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Download Prescription',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      const Text(
                        'Follow-Up Suggestions:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _reportDetails!['follow_up_suggestions'] ??
                            'No follow-up suggestions',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : const Center(child: Text('No details available')),
    );
  }
}
