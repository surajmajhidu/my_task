import 'package:daily_task_x/services/auth_service.dart';
import 'package:daily_task_x/services/network_info_service.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'email_password_login_screen.dart';
import 'phone_login_screen.dart';
import 'package:daily_task_x/screens/home_screen.dart';
import 'package:daily_task_x/screens/auth/terms_and_conditions_screen.dart';

class LoginOptionsScreen extends StatefulWidget { // Converted to StatefulWidget
  const LoginOptionsScreen({super.key});

  @override
  State<LoginOptionsScreen> createState() => _LoginOptionsScreenState();
}

class _LoginOptionsScreenState extends State<LoginOptionsScreen> { // State class
  final AuthService _authService = AuthService();
  final NetworkInfoService _networkInfoService = NetworkInfoService(); // Added
  bool _isCheckingVpn = false; // Added for loading state during VPN check

  // Helper method for VPN check
  Future<bool> _performVpnCheckAndShowMessage() async {
    setState(() => _isCheckingVpn = true);
    bool vpnDetected = await _networkInfoService.isVpnOrProxyDetected();
    setState(() => _isCheckingVpn = false);

    if (vpnDetected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("VPN detected. Please disable VPN to continue using DailyTaskX."),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return true;
    }
    return false;
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (await _performVpnCheckAndShowMessage()) return; // VPN Check

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      bool needsTermsAndConditions = await _authService.signInWithGoogle();
      Navigator.pop(context); 

      if (FirebaseAuth.instance.currentUser != null) {
        if (needsTermsAndConditions) {
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google Sign-In cancelled or failed before user creation.')),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); 
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Error: ${e.message ?? "Unknown error"}')),
        );
      }
    } on SecurityCheckException catch (e) {
      Navigator.pop(context); 
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      Navigator.pop(context); 
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to DailyTaskX'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isCheckingVpn 
              ? const CircularProgressIndicator() // Show loading indicator during VPN check
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Sign in with Google'),
                      onPressed: () => _signInWithGoogle(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.email),
                      label: const Text('Sign in with Email'),
                      onPressed: () async {
                        if (await _performVpnCheckAndShowMessage()) return; // VPN Check
                        if (mounted) { // Check if widget is still in the tree
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EmailPasswordLoginScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.phone),
                      label: const Text('Sign in with Phone'),
                      onPressed: () async {
                        if (await _performVpnCheckAndShowMessage()) return; // VPN Check
                         if (mounted) { // Check if widget is still in the tree
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
