import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Screens/doctorhome.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Patient {
  final String name;
  final int age;
  final String work;
  final String? imageBase64;

  Patient({
    required this.name,
    required this.age,
    required this.work,
    this.imageBase64,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      name: json['name'],
      age: json['age'],
      work: json['work'],
      imageBase64: json['image'],
    );
  }
}

Future<String?> getDoctorEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('doctorEmail');
}

Future<List<Patient>> fetchPatientInfo() async {
  final doctorEmail = await getDoctorEmail();
  if (doctorEmail == null) {
    throw Exception('Doctor email not found');
  }

  final response = await http.get(
    Uri.parse(
        'http://10.0.2.2:3000/api/users/patient-info?doctorEmail=$doctorEmail'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> patientsJson = json.decode(response.body);
    return patientsJson.map((json) => Patient.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load patient information');
  }
}

class FrequentPatientsPage extends StatefulWidget {
  @override
  _FrequentPatientsPageState createState() => _FrequentPatientsPageState();
}

class _FrequentPatientsPageState extends State<FrequentPatientsPage> {
  late Future<List<Patient>> futurePatients;

  @override
  void initState() {
    super.initState();
    futurePatients = fetchPatientInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4FF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DoctorHomeScreen(),
              ),
            );
          },
        ),
        title: const Text('Frequent patients'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Patient>>(
                future: futurePatients,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No patients found'));
                  } else {
                    final patients = snapshot.data!;
                    return ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 30,
                              backgroundImage: patient.imageBase64 != null
                                  ? MemoryImage(
                                      base64Decode(patient.imageBase64!))
                                  : AssetImage('assets/default_avatar.png')
                                      as ImageProvider,
                            ),
                            title: Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Age: ${patient.age}, Work: ${patient.work}',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              size: 20,
                            ),
                            onTap: () {
                              // Handle patient selection
                            },
                          ),
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
