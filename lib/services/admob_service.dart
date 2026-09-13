import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'reward_service.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // App ID Resmi: ca-app-pub-8640638285279807~1310378475
  // Unit ID Rewarded Resmi: ca-app-pub-8640638285279807/7637956984
  static const String liveRewardedAdUnitId = 'ca-app-pub-8640638285279807/7637956984';
  
  // Google Official Sample Test Unit ID (Mencegah banned invalid click saat masa development/testing)
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  /// Cek apakah iklan harus ditampilkan (Pengguna Bao Bao Premium bebas iklan)
  bool get shouldShowAds => !RewardService().isPremium;

  /// Otomatis menggunakan ID Resmi di versi rilis (APK/PlayStore), dan Test ID saat tahap debug coding
  static String get rewardedAdUnitId => kReleaseMode ? liveRewardedAdUnitId : testRewardedAdUnitId;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  /// Inisialisasi Mobile Ads dengan kepatuhan penuh Google Play Families Policy & COPPA
  Future<void> initialize() async {
    try {
      // 1. tagForChildDirectedTreatment = YES (Wajib untuk aplikasi anak di bawah 13 tahun)
      // 2. maxAdContentRating = G (Hanya iklan kategori umum ramah keluarga)
      final requestConfig = RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        maxAdContentRating: MaxAdContentRating.g,
        testDeviceIds: <String>[],
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfig);
      await MobileAds.instance.initialize();
      loadRewardedAd();
      debugPrint('✅ [AdMob] SDK berhasil diinisialisasi untuk NiHao Kids (COPPA Compliant).');
    } catch (e) {
      debugPrint('❌ [AdMob] Gagal inisialisasi: $e');
    }
  }

  /// Memuat Rewarded Ad di latar belakang
  void loadRewardedAd() {
    if (_isRewardedAdLoading || _rewardedAd != null) return;
    _isRewardedAdLoading = true;

    final targetUnitId = rewardedAdUnitId;
    debugPrint('⏳ [AdMob] Memuat Rewarded Ad dengan Unit ID: $targetUnitId');

    RewardedAd.load(
      adUnitId: targetUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoading = false;
          debugPrint('✅ [AdMob] Rewarded Ad siap ditampilkan!');
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedAdLoading = false;
          debugPrint('⚠️ [AdMob] Rewarded Ad gagal dimuat: ${error.message}');
        },
      ),
    );
  }

  /// Menampilkan Rewarded Ad untuk klaim Bambu & Bintang
  void showRewardedAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
  }) {
    if (_rewardedAd == null) {
      debugPrint('ℹ️ [AdMob] Iklan belum siap dimuat. Mencoba memuat ulang...');
      loadRewardedAd();
      // Fallback reward agar anak tidak kecewa saat offline / debug
      onUserEarnedReward();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (onAdClosed != null) onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        onUserEarnedReward();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (adWithoutView, reward) {
        debugPrint('🎉 [AdMob] Reward diterima: ${reward.amount} ${reward.type}');
        onUserEarnedReward();
      },
    );
  }
}
