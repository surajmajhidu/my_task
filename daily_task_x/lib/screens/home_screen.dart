import 'package:daily_task_x/services/ad_service.dart';
import 'package:daily_task_x/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:daily_task_x/screens/auth/login_options_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:daily_task_x/screens/claim_reward_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_task_x/screens/profile_screen.dart'; // Added for ProfileScreen navigation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AdService _adService = AdService();
  final AuthService _authService = AuthService();
  final String? _currentUserUID = FirebaseAuth.instance.currentUser?.uid;

  bool _isGlobalAdLoading = false;
  Map<int, bool> _adSlotLoadingStates = {};

  @override
  void initState() {
    super.initState();
  }

  void _watchAd(int slotIndex, int adsWatchedToday, int totalDailyAds) {
    if (adsWatchedToday >= totalDailyAds) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All ads for today already watched.')));
      return;
    }
    if (_isGlobalAdLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An ad is already in progress. Please wait.')));
      return;
    }
    if (!mounted) return;

    setState(() {
       _isGlobalAdLoading = true;
       _adSlotLoadingStates[slotIndex] = true;
    });

    _adService.loadRewardedAd(
      onAdLoaded: () {
        if (!mounted) {
          _resetAdLoadingStates(slotIndex);
          return;
        }
        _adService.showRewardedAd(context, (RewardItem reward) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClaimRewardScreen(reward: reward),
            ),
          ).then((_) {
            _resetAdLoadingStates(slotIndex);
          });
        });
      },
      onAdFailedToLoad: (String errorMessage) {
        if (!mounted) return;
        _resetAdLoadingStates(slotIndex);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ad failed to load: $errorMessage'))
        );
      },
      onUserEarnedReward: (RewardItem reward) {
        // Secondary callback
      },
      onAdDismissed: () {
        if (!mounted) return;
        _resetAdLoadingStates(slotIndex);
        print("Ad was dismissed or failed to show full screen without reward navigation.");
      }
    );
  }

  void _resetAdLoadingStates(int slotIndex) {
    if (mounted) {
      setState(() {
        _isGlobalAdLoading = false;
        _adSlotLoadingStates[slotIndex] = false;
      });
    } else {
        _isGlobalAdLoading = false;
        _adSlotLoadingStates[slotIndex] = false;
    }
  }

  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserUID == null) {
      return const Scaffold(body: Center(child: Text("Error: User not logged in.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DailyTaskX Home'),
        actions: [
          IconButton( // Added Profile Button
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginOptionsScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_currentUserUID).snapshots(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching user data: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(key: Key("loading_user_data")));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found. Please try logging out and in again.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final int totalPoints = userData['total_points'] ?? 0;
          final int adsWatchedToday = userData['ads_watched_today'] ?? 0;
          final int totalDailyAds = 15; 

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          'Total Points: $totalPoints',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Today\'s Ads: $adsWatchedToday / $totalDailyAds ads watched',
                          style: const TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_checkmark_outlined, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text("Network: Secure", style: TextStyle(fontSize: 16, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: totalDailyAds,
                    itemBuilder: (context, index) {
                      bool isSlotWatched = index < adsWatchedToday;
                      bool isThisSlotCurrentlyLoading = _adSlotLoadingStates[index] ?? false;

                      return Card(
                        elevation: isSlotWatched ? 1.0 : 3.0,
                        color: isSlotWatched ? Colors.grey[350] : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Ad Slot ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              const SizedBox(height: 5),
                              if (isSlotWatched)
                                const Icon(Icons.check_circle_outline, color: Colors.green, size: 36)
                              else if (isThisSlotCurrentlyLoading)
                                const CircularProgressIndicator()
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: (adsWatchedToday >= totalDailyAds || _isGlobalAdLoading)
                                      ? null 
                                      : () => _watchAd(index, adsWatchedToday, totalDailyAds),
                                  child: const Text('Watch', style: TextStyle(color: Colors.white)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
