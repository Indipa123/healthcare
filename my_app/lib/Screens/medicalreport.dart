import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/Screens/report.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/Screens/docdetail.dart';

class Medicalreport extends StatelessWidget {
  const Medicalreport({super.key, required String doctorEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Submit Medical Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

class SubmitReportPage extends StatefulWidget {
  final String doctorEmail;
  const SubmitReportPage({super.key, required this.doctorEmail});

  @override
  _SubmitReportPageState createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _selectedReportType;
  String? userEmail; // To store the user email

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail'); // Replace with your key
    });
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _importFile() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadReport() async {
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User email not found. Please login.')),
      );
      return;
    }

    if (_selectedImage == null || _selectedReportType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and report type.')),
      );
      return;
    }

    try {
      // Convert image to base64
      final bytes = await _selectedImage!.readAsBytes();
      final base64FileData = base64Encode(bytes);

      // Prepare request payload
      final body = jsonEncode({
        'user_email': userEmail,
        'doctor_email': widget.doctorEmail,
        'report_type': _selectedReportType,
        'file_data': base64FileData,
      });

      // Send POST request
      final uri =
          Uri.parse('http://192.168.8.195:3000/api/users/submit-report');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Show success popup
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              contentPadding: const EdgeInsets.all(16.0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Report Submission Successful',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your report has been uploaded successfully. You can view the feedback under the reports section.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportPage(),
                        ),
                      ); // Close dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('View Status'),
                  ),
                ],
              ),
            );
          },
        );
      } else {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['error'] ?? 'Failed to submit the report.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while submitting.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit medical report"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DoctorDetailScreen(email: widget.doctorEmail),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset(
                'assets/images/Doc.png', // You can replace this with the image you've uploaded
                height: 200,
              ),
              const SizedBox(height: 16),
              const Text(
                'Submit your report',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You can submit your medical report in two ways. You can take a photo of the report, or import it from your files.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                hint: const Text("Select Report Type"),
                value: _selectedReportType,
                items: <String>['Blood Report', 'X-Ray', 'Other']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedReportType = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: _importFile,
                    icon: const Icon(Icons.file_upload, color: Colors.white),
                    label: const Text(
                      "Import File",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor:
                          Colors.white, // Ensures icon and text color
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      "Take Photo",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor:
                          Colors.white, // Ensures icon and text color
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedImage != null)
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    border: Border.all(),
                  ),
                  child: Image.file(_selectedImage!),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _uploadReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                ),
                child: const Text(
                  "Upload",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
