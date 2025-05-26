import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart'; // For showing messages
import 'dart:io' show Platform; // Added for platform detection

class AdService {
  // Use AdMob's test Rewarded Ad Unit ID for now.
  // User MUST replace these with their own IDs.
  static const String _androidAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosAdUnitId = 'ca-app-pub-3940256099942544/1712485313';

  static String get _rewardedAdUnitId => Platform.isAndroid ? _androidAdUnitId : _iosAdUnitId;

  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;

  // Added a callback for when the ad is dismissed or fails to show, to allow UI to reset loading state
  VoidCallback? _onAdDismissedOrFailed;


  void loadRewardedAd({
    required VoidCallback onAdLoaded,
    required Function(String) onAdFailedToLoad,
    required Function(RewardItem) onUserEarnedReward,
    required VoidCallback onAdDismissed // Callback for when ad is dismissed
  }) {
    if (_isAdLoaded && _rewardedAd != null) {
        print("Ad already loaded.");
        onAdLoaded(); // If ad is already loaded, directly call onAdLoaded
        return;
    }
    if (_rewardedAd != null) { // If _rewardedAd is not null but _isAdLoaded is false, it might be from a previous failed load/show. Dispose it.
        _rewardedAd!.dispose();
        _rewardedAd = null;
    }

    _onAdDismissedOrFailed = onAdDismissed;


    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('RewardedAd loaded.');
          _rewardedAd = ad;
          _isAdLoaded = true;
          _setFullScreenContentCallback(onUserEarnedReward); // Pass the primary reward callback
          onAdLoaded();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedAd failed to load: $error');
          _isAdLoaded = false;
          _rewardedAd = null;
          onAdFailedToLoad(error.message);
          _onAdDismissedOrFailed?.call(); // Call dismiss callback on failure to load
        },
      ),
    );
  }

  void _setFullScreenContentCallback(Function(RewardItem) onUserEarnedRewardCallback) {
    if (_rewardedAd == null) return;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) => print('$ad onAdShowedFullScreenContent.'),
        onAdDismissedFullScreenContent: (RewardedAd ad) {
            print('$ad onAdDismissedFullScreenContent.');
            ad.dispose();
            _rewardedAd = null;
            _isAdLoaded = false;
            _onAdDismissedOrFailed?.call(); // Call dismiss callback
            // Consider pre-loading next ad here if needed
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
            print('$ad onAdFailedToShowFullScreenContent: $error');
            ad.dispose();
            _rewardedAd = null;
            _isAdLoaded = false;
            _onAdDismissedOrFailed?.call(); // Call dismiss callback
        },
        onAdImpression: (RewardedAd ad) => print('$ad impression occurred.'),
    );
  }

  void showRewardedAd(BuildContext context, Function(RewardItem) onUserEarnedReward) {
    if (_rewardedAd != null && _isAdLoaded) {
      // The onUserEarnedReward for _rewardedAd.show is the one that matters for granting reward.
      _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        print('REWARD: type=${reward.type}, amount=${reward.amount}');
        onUserEarnedReward(reward); // This is the primary reward callback passed from UI
      });
    } else {
      print('Rewarded ad is not ready yet.');
      // It's better to handle "ad not ready" in the UI before calling showRewardedAd,
      // e.g., by disabling the "Show Ad" button until onAdLoaded is called.
      // However, if called, provide feedback.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad not ready. Try again shortly or wait for load.')),
      );
      // Optionally try to load another ad, but be careful with multiple load calls
      // and managing callbacks correctly. The current design expects load to be called explicitly by UI.
    }
  }

  // Dispose method to clean up ad resources if AdService is disposed
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
