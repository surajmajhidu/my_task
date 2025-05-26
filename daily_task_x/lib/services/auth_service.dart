import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';

class SecurityCheckException implements Exception {
  final String message;
  SecurityCheckException(this.message);
  @override
  String toString() => 'SecurityCheckException: $message';
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<String?> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor;
      }
    } catch (e) {
      print('Error getting device ID: $e');
    }
    return null;
  }

  Future<String?> _getIpAddress() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['query'];
      } else {
        print('Error getting IP address: Status Code ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting IP address: $e');
    }
    return null;
  }

  Future<void> _checkIpAddressClash(String? ipAddress) async {
    if (ipAddress == null || ipAddress.isEmpty) {
      print('IP address is null or empty, skipping IP clash check.');
      return;
    }
    final querySnapshot = await _firestore
        .collection('users')
        .where('registration_ip_address', isEqualTo: ipAddress)
        .limit(1) // Check for at least one existing user with this IP
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      throw SecurityCheckException("Only one account is allowed per IP. Please contact support if this is an error.");
    }
  }

  Future<void> _checkDeviceIdClash(String? deviceId) async {
    if (deviceId == null || deviceId.isEmpty) {
      print('Device ID is null or empty, skipping device ID clash check.');
      return;
    }
    final querySnapshot = await _firestore
        .collection('users')
        .where('locked_device_id', isEqualTo: deviceId)
        .limit(1) // Check for at least one existing user with this device ID
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      throw SecurityCheckException("One device = One account. Multiple accounts from the same device are blocked.");
    }
  }

  // Modified return type to Future<bool>
  Future<bool> _storeUserData(User user, String? deviceId, String? ipAddress) async {
    DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);
    DocumentSnapshot docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      Map<String, dynamic> registrationData = {
        'uid': user.uid,
        'email': user.email,
        'phone': user.phoneNumber,
        'name': user.displayName,
        'registration_timestamp': FieldValue.serverTimestamp(),
        'locked_device_id': deviceId,
        'registration_ip_address': ipAddress,
        'total_points': 0,
        'ads_watched_today': 0,
        'terms_accepted': false, // Initialize terms_accepted to false for new users
      };
      registrationData.removeWhere((key, value) => value == null && key != 'name' && key != 'email' && key != 'phone');
      
      await userDocRef.set(registrationData);
      print('User data stored for NEW UID: ${user.uid}');
      return true; // New user
    } else {
      Map<String, dynamic> updateData = {};
      var existingData = docSnapshot.data() as Map<String, dynamic>?;

      if (existingData != null && existingData['locked_device_id'] == null && deviceId != null) {
        updateData['locked_device_id'] = deviceId;
      }
      // Do not update terms_accepted here for existing users, it's handled by TermsAndConditionsScreen or AuthWrapper
      if (updateData.isNotEmpty) {
        await userDocRef.update(updateData);
        print('User data updated for UID: ${user.uid} with fields: ${updateData.keys.join(', ')}');
      } else {
        print('Existing user UID: ${user.uid}. No new registration data to store or update for device/IP.');
      }
      return false; // Existing user
    }
  }

  // Modified return type to Future<bool> (true if T&C needed)
  Future<bool> registerWithEmailPassword(String email, String password) async {
    final String? deviceId = await _getDeviceId();
    final String? ipAddress = await _getIpAddress();
    await _checkIpAddressClash(ipAddress);
    await _checkDeviceIdClash(deviceId);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        return await _storeUserData(userCredential.user!, deviceId, ipAddress); // Returns true for new user
      }
      return false; // Should not happen if user creation succeeds
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async { // Kept original return type for login
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user != null) {
        final String? deviceId = await _getDeviceId();
        final String? ipAddress = await _getIpAddress(); 
        await _storeUserData(userCredential.user!, deviceId, ipAddress); // Call to update, but ignore bool for simple login
      }
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Modified return type to Future<UserCredential?> but logic for T&C is handled via additionalUserInfo.isNewUser
  // No, let's make it return Future<bool> as well for consistency in UI handling for new users.
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return false; // User cancelled, not a new user needing T&C in this path
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final User user = userCredential.user!;
        final bool isNewFirebaseUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        final String? deviceId = await _getDeviceId();
        final String? ipAddress = await _getIpAddress();

        if (isNewFirebaseUser) {
          try {
            await _checkIpAddressClash(ipAddress);
            await _checkDeviceIdClash(deviceId);
            return await _storeUserData(user, deviceId, ipAddress); // Returns true
          } catch (e) {
            await user.delete();
            print('Deleted Firebase user (${user.uid}) due to security check failure after Google sign-in.');
            throw e; 
          }
        } else {
          // Existing Firebase user, but might be first time _storeUserData runs if app was closed previously
          return await _storeUserData(user, deviceId, ipAddress); // Returns false if user doc existed
        }
      }
      return false; // Should not happen if user is not null
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // verifyPhoneNumber remains as Future<void> as it's a multi-stage process.
  // The decision to go to T&C will be handled in signInWithPhoneNumber or its verificationCompleted.
  Future<void> verifyPhoneNumber(String phoneNumber, {
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // This callback is tricky for returning a value directly to the UI caller of verifyPhoneNumber
        // The sign-in and T&C check logic will be more robustly handled in signInWithPhoneNumber
        // or by the UI checking after this callback.
        // For now, let's ensure data is stored. The UI will determine T&C based on User Doc after this.
        UserCredential userCredential = await _auth.signInWithCredential(credential);
        if (userCredential.user != null) {
          final bool isNewFirebaseUser = userCredential.additionalUserInfo?.isNewUser ?? false;
          final String? deviceId = await _getDeviceId();
          final String? ipAddress = await _getIpAddress();

          if (isNewFirebaseUser) {
             try {
                await _checkIpAddressClash(ipAddress);
                await _checkDeviceIdClash(deviceId);
                await _storeUserData(userCredential.user!, deviceId, ipAddress);
             } catch (e) {
                await userCredential.user!.delete();
                print('Deleted Firebase user (${userCredential.user!.uid}) due to security check failure after phone auto-verification.');
                if (e is SecurityCheckException) {
                   verificationFailed(FirebaseAuthException(code: 'security-check-failed', message: e.message));
                } else {
                  verificationFailed(FirebaseAuthException(code: 'unknown-error-during-security-check', message: 'An unknown error occurred during security checks.'));
                }
                return; // Stop further processing
             }
          } else {
            await _storeUserData(userCredential.user!, deviceId, ipAddress);
          }
        }
        verificationCompleted(credential); // Original callback
      },
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // Modified return type to Future<bool>
  Future<bool> signInWithPhoneNumber(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final User user = userCredential.user!;
        final bool isNewFirebaseUser = userCredential.additionalUserInfo?.isNewUser ?? false;
        
        final String? deviceId = await _getDeviceId();
        final String? ipAddress = await _getIpAddress();
        
        if (isNewFirebaseUser) {
          try {
            await _checkIpAddressClash(ipAddress);
            await _checkDeviceIdClash(deviceId);
            return await _storeUserData(user, deviceId, ipAddress); // Returns true
          } catch (e) {
            await user.delete();
            print('Deleted Firebase user (${user.uid}) due to security check failure after phone OTP sign-in.');
            throw e;
          }
        } else {
          return await _storeUserData(user, deviceId, ipAddress); // Returns false if user doc existed
        }
      }
      return false; // Should not happen
    } on FirebaseAuthException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
