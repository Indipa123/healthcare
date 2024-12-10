import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Add this import for PDF viewing

class ReportDetailsScreen extends StatefulWidget {
  final String? reportId;

  const ReportDetailsScreen({Key? key, this.reportId}) : super(key: key);

  @override
  _ReportDetailsScreenState createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  Map<String, dynamic>? reportDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReportDetails();
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

  Future<void> _viewReport(String base64FileData, String fileType) async {
    try {
      // Convert Base64 to file
      final bytes = base64Decode(base64FileData);
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/report.$fileType";

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // If the file is a PDF
      if (fileType == 'pdf') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewScreen(filePath: filePath),
          ),
        );
      } else {
        // Open the image file
        OpenFile.open(filePath);
      }
    } catch (e) {
      print("Error viewing report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open the report.")),
      );
    }
  }

  void _viewImage(String base64FileData, String fileType) async {
    try {
      // Convert Base64 to bytes
      final bytes = base64Decode(base64FileData);
      final tempDir = await getTemporaryDirectory();
      final filePath = "${tempDir.path}/image.$fileType";

      // Write image file to temporary directory
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Display the image in a new screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('View Image'),
            ),
            body: Center(
              child: Image.file(file),
            ),
          ),
        ),
      );
    } catch (e) {
      print("Error viewing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open the image.')),
      );
    }
  }

  Future<void> _downloadReport(String base64FileData, String fileType) async {
    try {
      // Convert Base64 to file
      final bytes = base64Decode(base64FileData);
      final downloadsDir = await getApplicationDocumentsDirectory();
      final filePath = "${downloadsDir.path}/report.$fileType";

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Report downloaded to $filePath")),
      );
    } catch (e) {
      print("Error downloading report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download the report.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Report Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Slight rounding
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reportDetails == null
              ? const Center(child: Text("No details available"))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reportDetails!['report_type'] ?? "Unknown Report",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Submitted: ${reportDetails!['created_at'] ?? 'Unknown'}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                if (reportDetails?['fileData'] != null) {
                                  final fileType = reportDetails!['fileType'] ??
                                      'png'; // Assuming backend sends file type
                                  if (fileType == 'pdf') {
                                    _viewReport(
                                      reportDetails!['fileData'],
                                      'pdf',
                                    );
                                  } else if (['png', 'jpg', 'jpeg']
                                      .contains(fileType)) {
                                    _viewImage(
                                      reportDetails!['fileData'],
                                      fileType,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Unsupported file format.')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Slight rounding
                                ),
                              ),
                              child: const Text('View Report'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (reportDetails?['fileData'] != null) {
                                  final fileType =
                                      reportDetails!['fileType'] ?? 'pdf';
                                  _downloadReport(
                                    reportDetails!['fileData'],
                                    fileType,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      8), // Slight rounding
                                ),
                              ),
                              child: const Text('Download Report'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Prescription',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Enter drugs for the prescription',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Handle Upload Prescription Image action
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8), // Slight rounding
                            ),
                          ),
                          child: const Text('Upload prescription image'),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Feedback',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter your feedback',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle Submit Feedback action
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8), // Slight rounding
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 100,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Submit Feedback'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// PDF Viewing Screen
class PDFViewScreen extends StatelessWidget {
  final String filePath;

  const PDFViewScreen({Key? key, required this.filePath}) : super(key: key);

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
