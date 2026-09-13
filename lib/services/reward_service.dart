import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola reward anak (Bambu, Bintang, XP, dan Bao Bao Premium) secara aman (Anti-Hack Checksum)
class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  static const String _keyBamboo = 'nh_bamboo_val';
  static const String _keyStars = 'nh_stars_val';
  static const String _keyXP = 'nh_xp_val';
  static const String _keyPremium = 'nh_premium_val';
  static const String _keyUnlockedLevels = 'nh_unlocked_levels';
  static const String _keyChecksum = 'nh_sec_sig_v2';
  
  // Kunci garam rahasia aplikasi untuk mencegah manipulasi data lokal
  static const String _secretSalt = 'NiHaoKidsSecureSalt2026_BaoBaoPremium';

  int _bamboo = 10;
  int _stars = 15;
  int _xp = 50;
  bool _isPremium = false;
  List<String> _unlockedLessons = ['nursery_numbers', 'nursery_animals', 'sd_greetings_adv'];

  int get bamboo => _bamboo;
  int get stars => _stars;
  int get xp => _xp;
  bool get isPremium => _isPremium;
  List<String> get unlockedLessons => List.unmodifiable(_unlockedLessons);

  /// Inisialisasi dan verifikasi keaslian data dari HP
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedBamboo = prefs.getInt(_keyBamboo) ?? 10;
      final savedStars = prefs.getInt(_keyStars) ?? 15;
      final savedXP = prefs.getInt(_keyXP) ?? 50;
      final savedPremium = prefs.getBool(_keyPremium) ?? false;
      final savedLevels = prefs.getStringList(_keyUnlockedLevels) ?? _unlockedLessons;
      final savedChecksum = prefs.getString(_keyChecksum) ?? '';

      // Hitung checksum validasi
      final expectedChecksum = _generateChecksum(savedBamboo, savedStars, savedXP, savedPremium, savedLevels);

      if (savedChecksum.isNotEmpty && savedChecksum != expectedChecksum) {
        // PERINGATAN: File di HP telah dimanipulasi secara ilegal (Cheat/Root edit)!
        debugPrint('⚠️ [KEAMANAN] Terdeteksi manipulasi data lokal! Mereset ke saldo aman.');
        _bamboo = 10;
        _stars = 15;
        _xp = 50;
        _isPremium = false;
        await _persistData(prefs);
      } else {
        // Data sah & otentik
        _bamboo = savedBamboo;
        _stars = savedStars;
        _xp = savedXP;
        _isPremium = savedPremium;
        _unlockedLessons = savedLevels;
        debugPrint('✅ [RewardService] Data reward sah dimuat: Bambu=$_bamboo, Bintang=$_stars, XP=$_xp, Premium=$_isPremium');
      }
    } catch (e) {
      debugPrint('Error loading rewards: $e');
    }
  }

  /// Beli Paket "Bao Bao Premium" (Rp49.000 Lifetime)
  Future<void> purchasePremium() async {
    _isPremium = true;
    _bamboo += 100; // Bonus instan 100 Bambu
    _xp += 200;     // Bonus XP
    await _save();
    debugPrint('🎉 [RewardService] Bao Bao Premium AKTIF! Bebas iklan selamanya + 100 Bambu.');
  }

  /// Top Up Bambu via In-App Purchase (Mini 100, Small 250, Large 600, Mega 1500)
  Future<void> purchaseBambooPack(int amount) async {
    _bamboo += amount;
    await _save();
    debugPrint('🎋 [RewardService] Top Up Bambu berhasil: +$amount Bambu (Total: $_bamboo)');
  }

  /// Pulihkan Pembelian (Restore Purchases)
  Future<bool> restorePurchases() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPremium = prefs.getBool(_keyPremium) ?? false;
    if (savedPremium) {
      _isPremium = true;
      await _save();
      return true;
    }
    return false;
  }

  /// Tambah XP belajar (dengan bonus 20% jika pengguna Premium)
  Future<void> addXP(int baseXP) async {
    final effectiveXP = _isPremium ? (baseXP * 1.2).round() : baseXP;
    _xp += effectiveXP;
    await _save();
  }

  /// Tambah bambu & bintang dari menonton Iklan AdMob
  Future<void> addRewardFromAd({int bambooReward = 5, int starReward = 3}) async {
    _bamboo += bambooReward;
    _stars += starReward;
    await _save();
  }

  /// Tambah bintang setelah lulus kuis
  Future<void> addStars(int amount) async {
    _stars += amount;
    await _save();
  }

  /// Gunakan bambu untuk membuka kostum/stiker Panda
  Future<bool> spendBamboo(int amount) async {
    if (_bamboo >= amount) {
      _bamboo -= amount;
      await _save();
      return true;
    }
    return false; // Saldo tidak cukup
  }

  /// Buka level petualangan baru
  Future<void> unlockLesson(String lessonId) async {
    if (!_unlockedLessons.contains(lessonId)) {
      _unlockedLessons.add(lessonId);
      await _save();
    }
  }

  bool isLessonUnlocked(String lessonId) {
    return _unlockedLessons.contains(lessonId);
  }

  /// Simpan data dengan tanda tangan digital
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await _persistData(prefs);
  }

  Future<void> _persistData(SharedPreferences prefs) async {
    await prefs.setInt(_keyBamboo, _bamboo);
    await prefs.setInt(_keyStars, _stars);
    await prefs.setInt(_keyXP, _xp);
    await prefs.setBool(_keyPremium, _isPremium);
    await prefs.setStringList(_keyUnlockedLevels, _unlockedLessons);
    
    // Simpan tanda tangan kriptografi
    final sig = _generateChecksum(_bamboo, _stars, _xp, _isPremium, _unlockedLessons);
    await prefs.setString(_keyChecksum, sig);
  }

  /// Fungsi penghasil tanda tangan digital unik (Anti-Tamper Signature)
  String _generateChecksum(int b, int s, int xp, bool prem, List<String> levels) {
    final raw = '$b:$s:$xp:$prem:${levels.join(",")}:$_secretSalt';
    var hash = 0xcbf29ce484222325;
    for (var code in utf8.encode(raw)) {
      hash ^= code;
      hash *= 0x100000001b3;
    }
    return hash.toRadixString(16);
  }
}
