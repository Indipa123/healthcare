import 'package:flutter/material.dart';

class Patient {
  final String name;
  final int age;
  final String work;
  final String imagePath;

  Patient(
      {required this.name,
      required this.age,
      required this.work,
      required this.imagePath});
}

class FrequentPatientsPage extends StatelessWidget {
  final List<Patient> patients = [
    Patient(
        name: 'Mahen Gamage',
        age: 60,
        work: 'Software Developer',
        imagePath: 'assets/images/patient1.jpg'),
    Patient(
        name: 'Patient Name',
        age: 45,
        work: 'Teacher',
        imagePath: 'assets/images/patient2.jpg'),
    Patient(
        name: 'Patient Name',
        age: 38,
        work: 'Nurse',
        imagePath: 'assets/images/patient3.jpg'),
    Patient(
        name: 'Patient Name',
        age: 55,
        work: 'Accountant',
        imagePath: 'assets/images/patient4.jpg'),
    Patient(
        name: 'Patient Name',
        age: 27,
        work: 'Student',
        imagePath: 'assets/images/patient5.jpg'),
    Patient(
        name: 'Patient Name',
        age: 40,
        work: 'Manager',
        imagePath: 'assets/images/patient6.jpg'),
    Patient(
        name: 'Patient Name',
        age: 33,
        work: 'Chef',
        imagePath: 'assets/images/patient7.jpg'),
    Patient(
        name: 'Patient Name',
        age: 48,
        work: 'Lawyer',
        imagePath: 'assets/images/patient8.jpg'),
  ];

 FrequentPatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Frequent patients",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(patient.imagePath),
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
                          color: Colors.brown[400],
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                      onTap: () {
                        // Handle patient selection
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
