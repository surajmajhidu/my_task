import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NetworkInfoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetches current IP and checks for VPN/proxy using ip-api.com
  // Returns true if VPN/proxy is suspected, false otherwise.
  // NOTE: This is a basic check. For robust VPN detection, use a dedicated service
  // like IPQualityScore or VPNAPI.io with an API key.
  Future<bool> isVpnOrProxyDetected() async {
    String? currentIp;
    try {
      // Fetch IP address first
      // Using a different endpoint from ip-api that just gives IP to avoid confusion
      final ipResponse = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (ipResponse.statusCode == 200) {
        currentIp = jsonDecode(ipResponse.body)['ip'];
      } else {
        print('Failed to fetch IP: ${ipResponse.statusCode}');
        return false; // Fail safe: if IP fetch fails, assume no VPN
      }

      // Then check this IP for proxy/VPN info using ip-api.com
      // Replace this with a call to a proper VPN detection service and API key.
      // Ensure currentIp is not null and is a valid IP before making this call.
      if (currentIp == null || currentIp.isEmpty) {
        print('IP address is null or empty after fetch, cannot check VPN.');
        return false; // Cannot check VPN without an IP
      }
      
      // Corrected URI for ip-api.com call
      final response = await http.get(Uri.parse('http://ip-api.com/json/$currentIp?fields=proxy,query'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool isProxy = data['proxy'] == true; // 'proxy' field indicates VPN/proxy/Tor
        if (isProxy) {
          await _logVpnAttempt(data['query'], 'ip-api.com detected proxy: true');
          return true;
        }
        return false;
      } else {
        // If the VPN check API fails, log it but don't necessarily block the user.
        print('VPN check API (ip-api.com) failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during VPN/proxy check: $e');
      // Fallback: if the API call fails, assume no VPN to avoid blocking users unnecessarily
      // A more robust solution would handle this based on the type of error.
    }
    return false; // Default to no VPN detected on error or if not explicitly true
  }

  Future<void> _logVpnAttempt(String? ipAddress, String apiResponse) async {
    User? currentUser = _auth.currentUser;
    // Log even if user is null, as this can happen before login
    
    if (ipAddress == null || ipAddress.isEmpty) {
        print("VPN log: IP address is null or empty, cannot log effectively.");
        // Optionally still log with currentUser.uid if that's valuable
    }

    _firestore.collection('logs').add({
      'uid': currentUser?.uid, // May be null if checked before login
      'event_type': 'vpn_detected_attempt',
      'timestamp': FieldValue.serverTimestamp(),
      'details': {
        'ip_address': ipAddress ?? 'unknown',
        'api_response': apiResponse,
        'checked_at': DateTime.now().toIso8601String(),
      }
    });
  }
}
