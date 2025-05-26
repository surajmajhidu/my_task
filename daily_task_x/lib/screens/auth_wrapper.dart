import 'package:daily_task_x/screens/home_screen.dart';
import 'package:daily_task_x/screens/auth/login_options_screen.dart';
import 'package:daily_task_x/screens/auth/terms_and_conditions_screen.dart';
import 'package:daily_task_x/services/network_info_service.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatefulWidget { // Converted to StatefulWidget
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver { // Added WidgetsBindingObserver
  final NetworkInfoService _networkInfoService = NetworkInfoService();
  bool _isVpnDetected = false;
  bool _isLoadingVpnCheck = true;
  String _vpnCheckMessage = "VPN detected. Please disable VPN and restart the app or press Retry.";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observe app lifecycle
    _performVpnCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Perform VPN check when app is resumed
      print("App resumed, re-checking VPN...");
      _performVpnCheck();
    }
  }

  Future<void> _performVpnCheck() async {
    if (!mounted) return; // Ensure widget is still in the tree
    setState(() {
      _isLoadingVpnCheck = true;
    });
    bool vpn = await _networkInfoService.isVpnOrProxyDetected();
    if (!mounted) return;
    setState(() {
      _isVpnDetected = vpn;
      _isLoadingVpnCheck = false;
      if (vpn) {
        // _vpnCheckMessage is already set, but could be updated if needed
      }
    });
  }

  Widget _buildVpnDetectedScreen() {
    return Scaffold(
      key: const Key('vpn_detected_screen'), // Added key for testing/identification
      appBar: AppBar(
        title: const Text("Network Alert"),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                _vpnCheckMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _performVpnCheck,
                child: const Text("Retry Network Check"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingVpnCheck) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(key: Key('vpn_initial_check_loading'))));
    }

    if (_isVpnDetected) {
      return _buildVpnDetectedScreen();
    }

    // If VPN not detected and check is complete, proceed with auth logic
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(key: Key('auth_wrapper_loading'))));
        }
        
        if (authSnapshot.hasData && authSnapshot.data != null) {
          final User user = authSnapshot.data!;
          return FutureBuilder<DocumentSnapshot>(
            key: ValueKey(user.uid),
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, userDocSnapshot) {
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator(key: Key('user_doc_loading'))));
              }

              if (userDocSnapshot.hasError) {
                print("Error fetching user document: ${userDocSnapshot.error}");
                return const LoginOptionsScreen(); 
              }

              if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
                final data = userDocSnapshot.data!.data() as Map<String, dynamic>?;
                if (data != null && data['terms_accepted'] == true) {
                  return const HomeScreen();
                } else {
                  return const TermsAndConditionsScreen();
                }
              } else {
                print("User document for ${user.uid} does not exist, but user is authenticated. Navigating to T&C.");
                return const TermsAndConditionsScreen(); 
              }
            },
          );
        }
        return const LoginOptionsScreen();
      },
    );
  }
}
