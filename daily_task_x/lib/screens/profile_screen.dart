import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_task_x/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final String? _currentUserUID = FirebaseAuth.instance.currentUser?.uid;
  final TextEditingController _upiController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For UPI ID validation
  bool _isSavingUpi = false;

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _saveUpiId() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUserUID == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
        return;
      }
      setState(() => _isSavingUpi = true);
      String upiValue = _upiController.text.trim();
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserUID!)
            .update({'upi_id': upiValue});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("UPI ID updated successfully!")),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update UPI ID: $error")),
          );
        }
        print("Failed to update UPI ID: $error");
      } finally {
        if (mounted) {
          setState(() => _isSavingUpi = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserUID == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text("Error: User not logged in. Please restart the app.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton( // Add back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_currentUserUID).snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile data not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          // Update UPI controller text if it's different from Firestore (e.g., initial load)
          // This check helps prevent cursor jumping if user is typing and stream rebuilds
          if (_upiController.text != (userData['upi_id'] ?? '')) {
             _upiController.text = userData['upi_id'] ?? '';
          }


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildInfoTile(title: 'Name', value: userData['name'] ?? 'Not set'),
                  _buildInfoTile(title: 'Email', value: userData['email'] ?? 'Not set'),
                  _buildInfoTile(title: 'Phone', value: userData['phone'] ?? 'Not set'),
                  const SizedBox(height: 10),
                  _buildInfoTile(title: 'Registered IP', value: userData['registration_ip_address'] ?? 'N/A', isEditable: false),
                  _buildInfoTile(title: 'Device ID', value: userData['locked_device_id'] ?? 'N/A', isEditable: false),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _upiController,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID (e.g., yourname@bank)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        // Allow empty UPI ID if user wants to clear it
                        return null; 
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid UPI ID (e.g., name@bank)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _isSavingUpi
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.save_alt_outlined),
                          label: const Text('Save UPI ID'),
                          onPressed: _saveUpiId,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50), // Full width
                          ),
                        ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    onPressed: () async {
                      await _authService.signOut();
                      // AuthWrapper will handle navigation.
                      // If ProfileScreen was pushed with Navigator.push, it will be automatically
                      // removed from the stack when AuthWrapper rebuilds.
                      // No explicit pop needed here if that's the case.
                      // If it was pushed with pushReplacement, then this screen would remain until AuthWrapper rebuilds.
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 50), // Full width
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile({required String title, required String value, bool isEditable = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: isEditable ? FontWeight.normal : FontWeight.bold),
          ),
          if (isEditable) const Divider() else const SizedBox(height: 8),
        ],
      ),
    );
  }
}
