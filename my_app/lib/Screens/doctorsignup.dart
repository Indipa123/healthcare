import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DoctorSignUpScreen extends StatefulWidget {
  const DoctorSignUpScreen({super.key});

  @override
  _DoctorSignUpScreenState createState() => _DoctorSignUpScreenState();
}

class _DoctorSignUpScreenState extends State<DoctorSignUpScreen> {
  final _nameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _specializationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agreeTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Sign Up',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            _buildTextField(
              controller: _nameController,
              hintText: 'Enter your name',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            // Medical License Number field
            _buildTextField(
              controller: _licenseController,
              hintText: 'Medical License Number',
              icon: Icons.badge,
            ),
            const SizedBox(height: 16),

            // Specialization field
            _buildTextField(
              controller: _specializationController,
              hintText: 'Specialization',
              icon: Icons.local_hospital,
            ),
            const SizedBox(height: 16),

            // Email field
            _buildTextField(
              controller: _emailController,
              hintText: 'Enter your email',
              icon: Icons.email,
            ),
            const SizedBox(height: 16),

            // Password field
            _buildTextField(
              controller: _passwordController,
              hintText: 'Enter your password',
              icon: Icons.lock,
              obscureText: true,
              suffixIcon: Icons.visibility_off,
            ),
            const SizedBox(height: 16),

            // Terms and Conditions checkbox with Wrap widget
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Checkbox(
                  value: _agreeTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeTerms = value!;
                    });
                  },
                ),
                const Text('I agree to the healthcare '),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Terms of Service',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                const Text(' and '),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sign Up button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: _agreeTerms ? _signUp : null,
                child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),

            // Sign In link
            Center(
              child: GestureDetector(
                onTap: () {
                  // Navigate to sign-in screen
                },
                child: const Text(
                  "Already have an account? Sign In",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    IconData? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _signUp() async {
    if (_agreeTerms) {
      // Replace with your backend API URL
      const String apiUrl = 'http://10.0.2.2:3000/api/auth/signup';

      // Collect data from the input fields
      final Map<String, String> data = {
        "name": _nameController.text,
        "licenseNumber": _licenseController.text,
        "specialty": _specializationController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
      };

      try {
        // Make a POST request
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: json.encode(data),
        );

        // Check if the request was successful
        if (response.statusCode == 201) {
          // Parse the response
          final responseData = json.decode(response.body);

          // Handle the response (e.g., navigate to another screen or show a success message)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Sign-up successful: ${responseData['message']}')),
          );
        } else {
          // Handle errors
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-up failed: ${response.body}')),
          );
        }
      } catch (e) {
        // Handle any network errors or exceptions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    } else {
      // Show message to agree to terms
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to the terms and conditions')),
      );
    }
  }
}
