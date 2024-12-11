import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart'; // Add this import for PDF viewing

class ReportDetailsScreen extends StatefulWidget {
  final String? reportId;

  const ReportDetailsScreen({super.key, this.reportId});

  @override
  _ReportDetailsScreenState createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends State<ReportDetailsScreen> {
  Map<String, dynamic>? reportDetails;
  bool isLoading = true;
  TextEditingController feedbackController = TextEditingController();
  TextEditingController prescriptionController = TextEditingController();
  String? prescriptionImageBase64;
  String? doctorEmail;
  String? userEmail;

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

  Future<void> _submitFeedback() async {
    final reportId =
        widget.reportId; // Assuming reportId is passed from previous screen
    final feedbackText = feedbackController.text;
    final prescriptionText = prescriptionController.text;

    if (doctorEmail == null || userEmail == null) {
      // Ensure that doctorEmail and userEmail are available before submitting
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Report details not loaded yet. Please try again later.'),
        ),
      );
      return;
    }

    // Check if prescription image is valid
    if (prescriptionImageBase64 == null || prescriptionImageBase64!.isEmpty) {
      print("Prescription image is missing or invalid");
    }

    if (feedbackText.isEmpty) {
      print("Feedback text is empty");
    }

    // Log the data being sent to backend for debugging
    print('Report ID: $reportId');
    print('Doctor Email: $doctorEmail');
    print('User Email: $userEmail');
    print('Prescription Image Base64: $prescriptionImageBase64');
    print('Feedback Text: $feedbackText');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/auth/report/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'report_id': reportId,
          'doctor_email': doctorEmail,
          'user_email': userEmail,
          'prescription_details':
              prescriptionText, // Replace with actual details
          'prescription_image': prescriptionImageBase64, // Base64 encoded image
          'feedback': feedbackText,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feedback submitted successfully!')),
        );
      } else {
        throw Exception('Failed to submit feedback');
      }
    } catch (e) {
      print("Error submitting feedback: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit feedback')),
      );
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
      // Convert Base64 to file bytes
      final bytes = base64Decode(base64FileData);

      // Get the external storage directory (Android-specific)
      final directory = await getExternalStorageDirectory();

      if (directory == null) {
        throw Exception("Unable to access external storage directory.");
      }

      // Construct the path to the Downloads folder
      final downloadsPath =
          "${directory.parent.parent.parent.parent.path}/Download";

      // Generate a unique file name
      String fileName = "report";
      int counter = 1;
      String filePath;

      do {
        filePath =
            "$downloadsPath/$fileName${counter > 1 ? counter : ''}.$fileType";
        counter++;
      } while (await File(filePath).exists());

      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Report downloaded as $filePath")),
      );
    } catch (e) {
      print("Error downloading report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to download the report.")),
      );
    }
  }

  Future<void> _takePhotoOfPrescription() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      File imageFile = File(photo.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      setState(() {
        prescriptionImageBase64 = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo captured and ready to submit')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No photo captured')),
      );
    }
  }

  Future<void> _importPrescription() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      String filePath = result.files.single.path ?? '';
      File imageFile = File(filePath);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      setState(() {
        prescriptionImageBase64 = base64Image;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prescription imported: $filePath')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected.')),
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
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween, // Ensures even spacing
                          children: [
                            // View Report Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (reportDetails?['fileData'] != null) {
                                    final fileType =
                                        reportDetails!['fileType'] ??
                                            'png'; // Default file type
                                    if (fileType == 'pdf') {
                                      _viewReport(
                                          reportDetails!['fileData'], 'pdf');
                                    } else if (['png', 'jpg', 'jpeg']
                                        .contains(fileType)) {
                                      _viewImage(
                                          reportDetails!['fileData'], fileType);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Unsupported file format.')),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        8), // Rounded corners
                                  ),
                                ),
                                child: const Text('View Report'),
                              ),
                            ),
                            const SizedBox(width: 12), // Space between buttons
                            // Download Report Button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (reportDetails?['fileData'] != null) {
                                    final fileType =
                                        reportDetails!['fileType'] ?? 'png';
                                    if (!['pdf', 'jpg', 'jpeg', 'png']
                                        .contains(fileType.toLowerCase())) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("Unsupported file type.")),
                                      );
                                      return;
                                    }
                                    _downloadReport(reportDetails!['fileData'],
                                        fileType.toLowerCase());
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "No file data available to download.")),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        8), // Rounded corners
                                  ),
                                ),
                                child: const Text('Download Report'),
                              ),
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
                          controller: prescriptionController,
                          decoration: const InputDecoration(
                            hintText: 'Enter drugs for the prescription',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(8)), // Uniform rounding
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
// Row for horizontal button alignment
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Import Prescription Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _importPrescription, // Call the Import Prescription function
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.black,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(8)), // Uniform rounding
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14), // Adjust vertical padding
                                ),
                                icon: const Icon(Icons.upload_file),
                                label: const Text(
                                  'Import',
                                  style: TextStyle(
                                      fontSize: 14), // Adjust font size
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: 12), // Spacing between the two buttons
                            // Take Photo of Prescription Button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    _takePhotoOfPrescription, // Call the Take Photo of Prescription function
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.black,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(8)), // Uniform rounding
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14), // Adjust vertical padding
                                ),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text(
                                  'Take Photo',
                                  style: TextStyle(
                                      fontSize: 14), // Adjust font size
                                ),
                              ),
                            ),
                          ],
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
                          controller: feedbackController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enter your feedback',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double
                              .infinity, // Ensures the button spans the entire width
                          child: ElevatedButton(
                            onPressed: _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8), // Slight rounding
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical:
                                    12, // Remove horizontal padding for full width
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
