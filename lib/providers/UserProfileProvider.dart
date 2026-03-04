import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// ─────────────────────────────────────────────
//  POINTS PACKAGES (configurable pricing)
// ─────────────────────────────────────────────
class PointsPackage {
  final String id;
  final int points;
  final String price;
  final String label;
  final bool isBestValue;

  const PointsPackage({
    required this.id,
    required this.points,
    required this.price,
    required this.label,
    this.isBestValue = false,
  });
}

const kPointsPackages = [
  PointsPackage(id: 'points_10', points: 10,  price: '\$0.99',  label: 'Starter'),
  PointsPackage(id: 'points_50', points: 50,  price: '\$3.99',  label: 'Popular',  isBestValue: true),
  PointsPackage(id: 'points_120', points: 120, price: '\$7.99',  label: 'Value'),
];

// ─────────────────────────────────────────────
//  AD UNIT IDs  — swap test IDs for production
// ─────────────────────────────────────────────
class _AdIds {
  // Test IDs — replace before shipping
  static const rewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const interstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const banner = 'ca-app-pub-3940256099942544/6300978111';
}

// ─────────────────────────────────────────────
//  WATCH HISTORY ENTRY
// ─────────────────────────────────────────────
class WatchHistoryEntry {
  final String seriesId;
  final String seriesTitle;
  final int episodeNumber;
  final int season;
  final DateTime watchedAt;

  const WatchHistoryEntry({
    required this.seriesId,
    required this.seriesTitle,
    required this.episodeNumber,
    required this.season,
    required this.watchedAt,
  });
}

// ─────────────────────────────────────────────
//  USER PROFILE PROVIDER
// ─────────────────────────────────────────────
class UserProfileProvider extends ChangeNotifier {
  // ── State ─────────────────────────────────
  int _points;
  bool _isPremium;
  bool _isAdLoading = false;
  String? _adErrorMessage;
  int _adsWatchedToday = 0;
  int _totalPointsEarned = 0;
  DateTime? _lastAdWatchedAt;

  // Premium gives unlimited access
  static const int kFreePoints = 3;       // Starting balance
  static const int kMaxAdsPerDay = 10;    // Daily ad cap to prevent abuse
  static const int kPointsPerAd = 1;      // Points rewarded per ad view
  static const int kPointsPerEpisode = 1; // Cost to unlock one episode

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;

  final List<WatchHistoryEntry> _watchHistory = [];
  List<WatchHistoryEntry> get watchHistory =>
      List.unmodifiable(_watchHistory.reversed.toList());

  // ── Constructor ───────────────────────────
  UserProfileProvider({
    int initialPoints = kFreePoints,
    bool isPremium = false,
  })  : _points = initialPoints,
        _isPremium = isPremium {
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  // ── Getters ───────────────────────────────
  int get points => _points;
  bool get isPremium => _isPremium;
  bool get isAdLoading => _isAdLoading;
  bool get isAdReady => _rewardedAd != null;
  String? get adErrorMessage => _adErrorMessage;
  int get adsWatchedToday => _adsWatchedToday;
  int get totalPointsEarned => _totalPointsEarned;
  bool get canWatchAd =>
      !_isPremium &&
          _rewardedAd != null &&
          _adsWatchedToday < kMaxAdsPerDay;
  bool get dailyAdLimitReached => _adsWatchedToday >= kMaxAdsPerDay;

  // ── Ad Loading ────────────────────────────
  void _loadRewardedAd() {
    _isAdLoading = true;
    _adErrorMessage = null;
    notifyListeners();

    RewardedAd.load(
      adUnitId: _AdIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
          _adErrorMessage = 'No ads available right now. Try again later.';
          notifyListeners();
          debugPrint('[AdMob] Rewarded ad failed to load: ${error.message}');
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          debugPrint('[AdMob] Interstitial failed: ${error.message}');
        },
      ),
    );
  }

  // ── Public: Watch Ad for Points ───────────
  Future<AdWatchResult> watchAdForPoints() async {
    if (_isPremium) return AdWatchResult.premiumUser;
    if (_rewardedAd == null) return AdWatchResult.notReady;
    if (_adsWatchedToday >= kMaxAdsPerDay) return AdWatchResult.dailyLimitReached;

    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Pre-load for next time
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        notifyListeners();
        debugPrint('[AdMob] Failed to show rewarded ad: ${error.message}');
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewarded = true;
        _points += kPointsPerAd;
        _totalPointsEarned += kPointsPerAd;
        _adsWatchedToday += 1;
        _lastAdWatchedAt = DateTime.now();
        notifyListeners();
      },
    );

    return rewarded ? AdWatchResult.success : AdWatchResult.skipped;
  }

  // ── Public: Show Interstitial ─────────────
  /// Call this between episode swipes (every 3 swipes)
  void showInterstitialIfReady() {
    if (_isPremium) return; // No ads for premium users
    if (_interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
  }

  // ── Public: Episode Unlock ────────────────
  EpisodeUnlockResult consumePoint() {
    if (_isPremium) return EpisodeUnlockResult.success; // Free for premium
    if (_points <= 0) return EpisodeUnlockResult.noPoints;

    _points -= kPointsPerEpisode;
    notifyListeners();
    return EpisodeUnlockResult.success;
  }

  // ── Public: Add Points (IAP) ──────────────
  void addPointsFromPurchase(int amount) {
    _points += amount;
    _totalPointsEarned += amount;
    notifyListeners();
  }

  // ── Public: Activate Premium ──────────────
  void activatePremium() {
    _isPremium = true;
    notifyListeners();
  }

  // ── Watch History ─────────────────────────
  void recordWatched({
    required String seriesId,
    required String seriesTitle,
    required int episodeNumber,
    required int season,
  }) {
    _watchHistory.add(WatchHistoryEntry(
      seriesId: seriesId,
      seriesTitle: seriesTitle,
      episodeNumber: episodeNumber,
      season: season,
      watchedAt: DateTime.now(),
    ));
    notifyListeners();
  }

  // ── Reset daily ad counter (call from a scheduler) ──
  void resetDailyAdCount() {
    _adsWatchedToday = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
//  RESULT ENUMS  (instead of silent booleans)
// ─────────────────────────────────────────────
enum AdWatchResult {
  success,
  skipped,
  notReady,
  dailyLimitReached,
  premiumUser,
}

enum EpisodeUnlockResult {
  success,
  noPoints,
}