import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http; // For API requests
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart'; // Update this with the actual path to your PDF viewer screen

class DReportDetailScreen extends StatefulWidget {
  final String reportId; // Pass a unique identifier for the report

  const DReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  _DReportDetailScreenState createState() => _DReportDetailScreenState();
}

class _DReportDetailScreenState extends State<DReportDetailScreen> {
  Map<String, dynamic>? reportDetails;
  Map<String, dynamic>? prescriptionDetails;
  bool isLoading = true;
  String? doctorEmail;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _fetchReportDetails();
    fetchPrescriptionDetail();
  }

  Future<void> _fetchReportDetails() async {
    try {
      setState(() => isLoading = true);

      // Fetch report details from backend
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/auth/report/${widget.reportId}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> fetchedDetails = json.decode(response.body);

        setState(() {
          doctorEmail = fetchedDetails[
              'doctor_email']; // Assuming these fields exist in the response
          userEmail = fetchedDetails['user_email'];
          reportDetails = fetchedDetails;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load report details');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching report details: $e");
    }
  }

  Future<void> fetchPrescriptionDetail() async {
    final url = Uri.parse(
        "http://10.0.2.2:3000/api/users/prescriptions/${widget.reportId}"); // Update with your API endpoint
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        prescriptionDetails = jsonDecode(response.body);
      });
    } else {
      throw Exception("Failed to fetch prescription details");
    }
  }

  Future<void> _viewFile(
      String base64FileData, String fileType, BuildContext context) async {
    try {
      final bytes = base64Decode(base64FileData);
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/temp_file.$fileType";

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (fileType == 'pdf') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewScreen(filePath: filePath),
          ),
        );
      } else {
        OpenFile.open(filePath);
      }
    } catch (e) {
      print("Error viewing file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open the file.")),
      );
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportDetails != null
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
                        reportDetails!['created_at'] ?? 'Unknown Date',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Type of Report:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reportDetails!['report_type'] ?? 'Unknown Type',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: () {
                            if (reportDetails?["fileData"] != null) {
                              final fileType =
                                  reportDetails!["fileType"] ?? 'png';
                              _viewFile(reportDetails!["fileData"], fileType,
                                  context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "No file data available to view.")),
                              );
                            }
                          },
                          child: const Text(
                            "View Report",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (prescriptionDetails != null) ...[
                        const Text(
                          "Prescribed Medications:",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescriptionDetails!['prescription_details'] ??
                              'No follow-up suggestions',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            onPressed: () {
                              if (prescriptionDetails?["prescriptionImage"] !=
                                  null) {
                                final fileType =
                                    prescriptionDetails!["fileType"] ?? 'png';
                                _viewFile(
                                    prescriptionDetails!["prescriptionImage"],
                                    fileType,
                                    context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "No prescription data available to view.")),
                                );
                              }
                            },
                            child: const Text(
                              "View Prescription",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Follow-Up Suggestions:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescriptionDetails!['feedback'] ??
                              'No follow-up suggestions',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : const Center(child: Text("No report details available.")),
    );
  }
}

// PDF Viewing Screen
class PDFViewScreen extends StatelessWidget {
  final String filePath;

  const PDFViewScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF View'),
      ),
      body: Center(
        child: PDFView(
          filePath: filePath,
        ),
      ),
    );
  }
}
