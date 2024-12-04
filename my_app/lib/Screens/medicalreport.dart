import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const Medicalreport());
}

class Medicalreport extends StatelessWidget {
  const Medicalreport({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Submit Medical Report',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SubmitReportPage(),
    );
  }
}

class SubmitReportPage extends StatefulWidget {
  const SubmitReportPage({super.key});

  @override
  _SubmitReportPageState createState() => _SubmitReportPageState();
}

class _SubmitReportPageState extends State<SubmitReportPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _selectedReportType;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit medical report"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
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
                  icon: const Icon(Icons.file_upload),
                  label: const Text("Import File"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take Photo"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
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
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Handle the report submission here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
              ),
              child: const Text("Upload"),
            ),
          ],
        ),
      ),
    );
  }
}
