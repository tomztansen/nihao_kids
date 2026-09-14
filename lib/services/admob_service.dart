import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'reward_service.dart';

/// Hybrid Ads Engine: Google AdMob (Prioritas 1) + Unity Ads (Otomatis Fallback jika AdMob kosong/gagal)
class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // ==========================================
  // 1. KONFIGURASI GOOGLE ADMOB
  // ==========================================
  // App ID Resmi: ca-app-pub-8640638285279807~1310378475
  static const String liveRewardedAdUnitId = 'ca-app-pub-8640638285279807/7637956984';
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static String get rewardedAdUnitId => kReleaseMode ? liveRewardedAdUnitId : testRewardedAdUnitId;

  // ==========================================
  // 2. KONFIGURASI UNITY ADS (FALLBACK)
  // ==========================================
  // Ganti dengan Game ID Android Anda dari Unity Dashboard (cloud.unity.com)
  static const String liveUnityGameId = '5731234'; 
  static const String testUnityGameId = '4798991'; // Unity Sample Test Game ID
  static String get unityGameId => kReleaseMode ? liveUnityGameId : testUnityGameId;
  static const String unityRewardedPlacementId = 'Rewarded_Android';

  // Cek apakah iklan harus ditampilkan (Pengguna Bao Bao Premium bebas iklan)
  bool get shouldShowAds => !RewardService().isPremium;

  RewardedAd? _admobRewardedAd;
  bool _isAdmobLoading = false;
  bool _isUnityInitialized = false;

  /// Inisialisasi kedua SDK (AdMob + Unity Ads) dengan kepatuhan COPPA & Google Play Families
  Future<void> initialize() async {
    // 1. Inisialisasi Google AdMob
    try {
      final requestConfig = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        maxAdContentRating: MaxAdContentRating.g,
        testDeviceIds: <String>[],
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfig);
      await MobileAds.instance.initialize();
      loadAdMobRewardedAd();
      debugPrint('✅ [AdMob] Inisialisasi berhasil (Prioritas 1).');
    } catch (e) {
      debugPrint('⚠️ [AdMob] Gagal inisialisasi: $e');
    }

    // 2. Inisialisasi Unity Ads (Fallback)
    try {
      await UnityAds.init(
        gameId: unityGameId,
        testMode: !kReleaseMode,
        onComplete: () {
          _isUnityInitialized = true;
          debugPrint('✅ [Unity Ads] Inisialisasi berhasil (Fallback Cadangan).');
          loadUnityRewardedAd();
        },
        onFailed: (error, message) {
          _isUnityInitialized = false;
          debugPrint('⚠️ [Unity Ads] Gagal inisialisasi: $error ($message)');
        },
      );
    } catch (e) {
      debugPrint('⚠️ [Unity Ads] Exception inisialisasi: $e');
    }
  }

  /// Memuat AdMob Rewarded Ad
  void loadAdMobRewardedAd() {
    if (_isAdmobLoading || _admobRewardedAd != null) return;
    _isAdmobLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _admobRewardedAd = ad;
          _isAdmobLoading = false;
          debugPrint('✅ [AdMob] Rewarded Ad siap ditayangkan!');
        },
        onAdFailedToLoad: (error) {
          _admobRewardedAd = null;
          _isAdmobLoading = false;
          debugPrint('ℹ️ [AdMob] Gagal memuat (${error.message} [Kode: ${error.code}]).');
          debugPrint('ℹ️ [AdMob] Jika akun/unit iklan masih dalam peninjauan (Under Review), fallback Unity Ads otomatis aktif.');
        },
      ),
    );
  }

  /// Memuat Unity Rewarded Ad
  void loadUnityRewardedAd() {
    if (!_isUnityInitialized) return;
    UnityAds.load(
      placementId: unityRewardedPlacementId,
      onComplete: (placementId) => debugPrint('✅ [Unity Ads] Rewarded Video ($placementId) siap siaga!'),
      onFailed: (placementId, error, message) => debugPrint('ℹ️ [Unity Ads] Load status: $message'),
    );
  }

  /// Menampilkan Iklan: Google AdMob Dulu -> Jika Gagal/Kosong -> Otomatis Fallback ke Unity Ads!
  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (!shouldShowAds) {
      onUserEarnedReward();
      return;
    }

    // TAHAP 1: Cek apakah Google AdMob siap tayang
    if (_admobRewardedAd != null) {
      debugPrint('🎬 [Ads Engine] Menayangkan iklan utama: Google AdMob...');
      _admobRewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _admobRewardedAd = null;
          loadAdMobRewardedAd();
          if (onAdClosed != null) onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('⚠️ [AdMob] Gagal tampil saat diputar. Mengalihkan ke Unity Ads (Fallback)...');
          ad.dispose();
          _admobRewardedAd = null;
          loadAdMobRewardedAd();
          _showUnityRewarded(onUserEarnedReward: onUserEarnedReward, onAdClosed: onAdClosed);
        },
      );

      _admobRewardedAd!.show(
        onUserEarnedReward: (adWithoutView, reward) {
          debugPrint('🎉 [AdMob] Reward berhasil diperoleh!');
          onUserEarnedReward();
        },
      );
    } else {
      // TAHAP 2: AdMob belum siap / masih dalam review Google / no-fill -> Langsung FALLBACK ke Unity Ads!
      debugPrint('🔄 [Ads Engine] AdMob belum siap / akun masih di-review. Otomatis beralih ke Unity Ads!');
      loadAdMobRewardedAd(); // Coba muat AdMob lagi di background untuk penayangan berikutnya saat sudah diapprove
      _showUnityRewarded(onUserEarnedReward: onUserEarnedReward, onAdClosed: onAdClosed);
    }
  }

  /// Menayangkan Unity Rewarded Video
  void _showUnityRewarded({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (!_isUnityInitialized) {
      debugPrint('ℹ️ [Unity Ads] Belum terinisialisasi. Memberikan reward mode offline.');
      onUserEarnedReward();
      if (onAdClosed != null) onAdClosed();
      return;
    }

    UnityAds.showVideoAd(
      placementId: unityRewardedPlacementId,
      onStart: (placementId) => debugPrint('🎬 [Unity Ads] Video dimulai: $placementId'),
      onComplete: (placementId) {
        debugPrint('🎉 [Unity Ads] Video selesai ditonton! Reward diklaim.');
        onUserEarnedReward();
        loadUnityRewardedAd();
        if (onAdClosed != null) onAdClosed();
      },
      onSkipped: (placementId) {
        debugPrint('ℹ️ [Unity Ads] Video dilewati oleh pengguna.');
        loadUnityRewardedAd();
        if (onAdClosed != null) onAdClosed();
      },
      onFailed: (placementId, error, message) {
        debugPrint('⚠️ [Unity Ads] Gagal tayang: $message. Memberikan reward aman untuk anak.');
        loadUnityRewardedAd();
        // Fallback offline agar anak tidak kecewa
        onUserEarnedReward();
        if (onAdClosed != null) onAdClosed();
      },
    );
  }
}
