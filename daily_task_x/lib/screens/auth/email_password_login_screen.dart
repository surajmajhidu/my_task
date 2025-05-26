import 'package:daily_task_x/services/auth_service.dart';
import 'package:daily_task_x/services/network_info_service.dart'; // Added
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:daily_task_x/screens/home_screen.dart';
import 'package:daily_task_x/screens/auth/terms_and_conditions_screen.dart';

class EmailPasswordLoginScreen extends StatefulWidget { // Converted to StatefulWidget
  const EmailPasswordLoginScreen({super.key});

  @override
  State<EmailPasswordLoginScreen> createState() => _EmailPasswordLoginScreenState();
}

class _EmailPasswordLoginScreenState extends State<EmailPasswordLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final NetworkInfoService _networkInfoService = NetworkInfoService(); // Added
  bool _isLoading = false;
  bool _isCheckingVpn = false; // Added for VPN check loading

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _loginUser() async {
    if (await _performVpnCheckAndShowMessage()) return; // VPN Check

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        UserCredential? userCredential = await _authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (userCredential != null && userCredential.user != null) {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login Failed: ${e.message ?? "Unknown error"}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _registerUser() async {
    if (await _performVpnCheckAndShowMessage()) return; // VPN Check

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        bool needsTermsAndConditions = await _authService.registerWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (FirebaseAuth.instance.currentUser != null) {
            if (needsTermsAndConditions) {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            } else {
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            }
        } else {
            if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registration failed. User not created.')),
                );
            }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration Failed: ${e.message ?? "Unknown error"}')),
          );
        }
      } on SecurityCheckException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Login/Register'),
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
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _loginUser,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text('Login'),
                          ),
                    const SizedBox(height: 15),
                    _isLoading
                        ? const SizedBox.shrink()
                        : ElevatedButton(
                            onPressed: _registerUser,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Colors.grey[700],
                            ),
                            child: const Text('Register'),
                          ),
                  ],
          ),
        ),
      ),
    );
  }
}
