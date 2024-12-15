import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _workController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail().then((_) {
      _fetchUserInfo();
    });
  }

  Future<void> _loadUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('userEmail');
    });
  }

  Future<void> _fetchUserInfo() async {
    if (userEmail == null) return;

    final response = await http.get(
      Uri.parse('http://192.168.8.195:3000/api/users/info?email=$userEmail'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _birthdayController.text = data['birthday'] ?? '';
        _contactController.text = data['contact']?.toString() ?? '';
        _addressController.text = data['address'] ?? '';
        _bloodTypeController.text = data['blood_type'] ?? '';
        _genderController.text = data['gender'] ?? '';
        _weightController.text = data['weight']?.toString() ?? '';
        _workController.text = data['work'] ?? '';
        _heightController.text = data['height']?.toString() ?? '';
      });
    } else {
      print("Failed to load user info.");
    }
  }

  Future<void> _saveUserInfo() async {
    if (userEmail == null) return;

    final response = await http.post(
      Uri.parse('http://192.168.8.195:3000/api/users/update'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': userEmail,
        'name': _nameController.text,
        'birthday': _birthdayController.text,
        'contact': _contactController.text,
        'address': _addressController.text,
        'blood_type': _bloodTypeController.text,
        'gender': _genderController.text,
        'weight': _weightController.text,
        'work': _workController.text,
        'height': _heightController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update information')),
      );
    }
  }

  Future<void> _pickAddressFromMap() async {
    LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(),
      ),
    );

    if (pickedLocation != null) {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pickedLocation.latitude,
        pickedLocation.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _addressController.text =
              '${placemark.street}, ${placemark.locality}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildTextField(_nameController, 'Name'),
            _buildTextField(_emailController, 'Email'),
            _buildTextField(_birthdayController, 'Birthday'),
            _buildTextField(_contactController, 'Contact'),
            _buildTextField(
              _addressController,
              'Address',
              onTap: _pickAddressFromMap,
              readOnly: true,
            ),
            _buildTextField(_bloodTypeController, 'Blood Type'),
            _buildTextField(_genderController, 'Gender'),
            _buildTextField(_weightController, 'Weight'),
            _buildTextField(_workController, 'Work'),
            _buildTextField(_heightController, 'Height'),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onPressed: _saveUserInfo,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool readOnly = false, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  late GoogleMapController _mapController;

  Future<void> _searchLocation() async {
    String query = _searchController.text;
    if (query.isNotEmpty) {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        _mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(location.latitude, location.longitude),
              zoom: 14,
            ),
          ),
        );
        setState(() {
          _selectedLocation = LatLng(location.latitude, location.longitude);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Address'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search location',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchLocation,
                ),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: (LatLng location) {
                setState(() {
                  _selectedLocation = location;
                });
              },
              markers: _selectedLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId('selected'),
                        position: _selectedLocation!,
                      ),
                    }
                  : {},
              initialCameraPosition: const CameraPosition(
                target: LatLng(6.9271, 79.8612), // Default location (Colombo)
                zoom: 12,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () {
          Navigator.pop(context, _selectedLocation);
        },
      ),
    );
  }
}
