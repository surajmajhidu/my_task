import 'dart:async';
import 'package:daily_task_x/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // For RewardItem
import 'package:lottie/lottie.dart'; // Optional: For Lottie animation on button

class ClaimRewardScreen extends StatefulWidget {
  final RewardItem reward;
  const ClaimRewardScreen({super.key, required this.reward});

  @override
  State<ClaimRewardScreen> createState() => _ClaimRewardScreenState();
}

class _ClaimRewardScreenState extends State<ClaimRewardScreen> with TickerProviderStateMixin {
  int _countdown = 30;
  Timer? _timer;
  bool _showClaimButton = false;
  bool _isClaiming = false;

  // For button animation
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { // Check if the widget is still in the tree
        timer.cancel();
        return;
      }
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _showClaimButton = true;
        });
        _animationController.forward(); // Start animation for button
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _claimPoints() async {
    if (!mounted) return;
    setState(() => _isClaiming = true);

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No user logged in. Please restart the app.')),
        );
        setState(() => _isClaiming = false);
      }
      // Optionally navigate back to login screen
      // Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginOptionsScreen()), (route) => false);
      return;
    }

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();

      // 1. Update User Document
      DocumentReference userDocRef = firestore.collection('users').doc(currentUser.uid);
      batch.update(userDocRef, {
        'total_points': FieldValue.increment(widget.reward.amount.toInt()), // Use actual reward amount
        'ads_watched_today': FieldValue.increment(1),
      });

      // 2. Add to /ads Collection
      DocumentReference adLogRef = firestore.collection('ads').doc(); // Auto-generate ID
      batch.set(adLogRef, {
        'uid': currentUser.uid,
        'ad_network_id': widget.reward.type, // Using reward.type as a placeholder for ad_network_id
        'watched_at': FieldValue.serverTimestamp(),
        'points_claimed': widget.reward.amount.toInt(),
        'status': 'claimed',
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.reward.amount.toInt()} points claimed!')),
        );
        // Navigate back to HomeScreen or pop this screen
        // Popping is simpler if this screen was pushed on top of HomeScreen
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error claiming points: ${e.toString()}')),
        );
      }
      print('Error claiming points: $e');
    } finally {
      if (mounted) {
        setState(() => _isClaiming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Claim Your Reward"),
          automaticallyImplyLeading: false, // No back button as it's disabled
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _isClaiming
                ? const CircularProgressIndicator()
                : _showClaimButton
                    ? ScaleTransition( // Button animation
                        scale: CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.elasticOut,
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.star),
                          label: Text("Claim ${widget.reward.amount.toInt()} Points"),
                          onPressed: _claimPoints,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Time remaining: $_countdown\s",
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Please wait $_countdown seconds to claim your reward.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 40),
                          // Optional Lottie animation for waiting
                          // SizedBox(
                          //   height: 150,
                          //   width: 150,
                          //   child: Lottie.asset('assets/lottie/timer_animation.json'), // Ensure you have this asset
                          // ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
