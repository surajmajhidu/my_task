import 'package:daily_task_x/services/auth_service.dart';
import 'package:daily_task_x/services/network_info_service.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import 'package:daily_task_x/screens/home_screen.dart';

class PhoneLoginScreen extends StatefulWidget { // Converted to StatefulWidget
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final NetworkInfoService _networkInfoService = NetworkInfoService(); // Added
  bool _isLoading = false; // For OTP sending
  bool _isCheckingVpn = false; // Added for VPN check loading

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

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

  Future<void> _sendOtp() async {
    if (await _performVpnCheckAndShowMessage()) return; // VPN Check

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String phoneNumber = _phoneController.text.trim();
      
      await _authService.verifyPhoneNumber(
        phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone number auto-verified and signed in successfully.')),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            String errorMessage = 'Phone number verification failed: ${e.message ?? "Unknown error"}';
            if (e.code == 'security-check-failed') {
                errorMessage = e.message ?? "Security check failed during phone verification.";
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMessage)),
            );
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(verificationId: verificationId),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            // setState(() => _isLoading = false); // Optional: depends on UX for timeout
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP auto-retrieval timed out. Please enter manually.')),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: _isCheckingVpn 
              ? const Center(child: CircularProgressIndicator(key: Key("vpn_check_indicator")))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (e.g., +1 XXX XXX XXXX)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (!value.startsWith('+') || value.length < 10) {
                          return 'Please enter a valid phone number with country code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _sendOtp,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text('Send OTP'),
                          ),
                  ],
          ),
        ),
      ),
    );
  }
}
