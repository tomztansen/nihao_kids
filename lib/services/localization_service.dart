import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { id, en }

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _prefKey = 'nh_app_language';
  static const String _manualOverrideKey = 'nh_lang_manual_override';

  late final ValueNotifier<AppLanguage> languageNotifier = ValueNotifier<AppLanguage>(detectSystemLanguage());
  bool _isManualOverride = false;

  AppLanguage get currentLanguage => languageNotifier.value;
  bool get isEnglish => currentLanguage == AppLanguage.en;
  bool get isManualOverride => _isManualOverride;

  /// Inisialisasi preferensi bahasa saat aplikasi pertama kali dijalankan
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isManualOverride = prefs.getBool(_manualOverrideKey) ?? false;
      final savedLang = prefs.getString(_prefKey);

      if (_isManualOverride && savedLang != null && (savedLang == 'en' || savedLang == 'id')) {
        languageNotifier.value = savedLang == 'en' ? AppLanguage.en : AppLanguage.id;
        debugPrint('🌐 [LocalizationService] Menggunakan preferensi manual tersimpan: ${languageNotifier.value.name.toUpperCase()}');
      } else {
        // Smart Auto-Detect: baca bahasa sistem perangkat HP
        final detected = detectSystemLanguage();
        languageNotifier.value = detected;
        debugPrint('🌐 [LocalizationService] Smart Auto-Detect sistem: ${detected.name.toUpperCase()}');
      }

      // Dengarkan jika bahasa sistem HP diubah di Settings saat aplikasi berjalan
      ui.PlatformDispatcher.instance.onLocaleChanged = () {
        _onSystemLocaleChanged();
      };
    } catch (e) {
      debugPrint('⚠️ [LocalizationService] Gagal memuat preferensi bahasa: $e');
    }
  }

  /// Deteksi bahasa sistem perangkat HP secara pintar (Smart Detection)
  static AppLanguage detectSystemLanguage() {
    try {
      // 1. Cek dari daftar urutan bahasa yang dipasang di HP Android
      final locales = ui.PlatformDispatcher.instance.locales;
      if (locales.isNotEmpty) {
        for (final loc in locales) {
          final code = loc.languageCode.toLowerCase();
          if (code == 'id' || code == 'in') {
            return AppLanguage.id;
          } else if (code == 'en') {
            return AppLanguage.en;
          }
        }
        final firstCode = locales.first.languageCode.toLowerCase();
        if (firstCode == 'id' || firstCode == 'in') {
          return AppLanguage.id;
        } else if (firstCode.isNotEmpty && firstCode != 'und') {
          return AppLanguage.en;
        }
      }

      // 2. Cek dari primary locale HP
      final primaryCode = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      if (primaryCode == 'id' || primaryCode == 'in') {
        return AppLanguage.id;
      } else if (primaryCode.isNotEmpty && primaryCode != 'und') {
        return AppLanguage.en;
      }
    } catch (e) {
      debugPrint('⚠️ [LocalizationService] Error detecting system locale: $e');
    }
    return AppLanguage.id;
  }

  void _onSystemLocaleChanged() async {
    if (!_isManualOverride) {
      final detected = detectSystemLanguage();
      languageNotifier.value = detected;
      debugPrint('🌐 [LocalizationService] Bahasa sistem HP berubah -> disesuaikan ke: ${detected.name.toUpperCase()}');
    }
  }

  /// Reset ke Smart Auto-Detect (Mengikuti bahasa sistem HP lagi)
  Future<void> resetToAutoDetect() async {
    _isManualOverride = false;
    final detected = detectSystemLanguage();
    languageNotifier.value = detected;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKey);
      await prefs.setBool(_manualOverrideKey, false);
      debugPrint('🌐 [LocalizationService] Preferensi direset ke Smart Auto-Detect: ${detected.name.toUpperCase()}');
    } catch (e) {
      debugPrint('⚠️ [LocalizationService] Gagal mereset ke Auto-Detect: $e');
    }
  }

  /// Beralih bahasa secara instan (1-klik)
  Future<void> toggleLanguage() async {
    final nextLang = isEnglish ? AppLanguage.id : AppLanguage.en;
    await setLanguage(nextLang);
  }

  /// Menyetel bahasa secara eksplisit dan menyimpannya secara persisten
  Future<void> setLanguage(AppLanguage language) async {
    _isManualOverride = true;
    languageNotifier.value = language;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language == AppLanguage.en ? 'en' : 'id');
      await prefs.setBool(_manualOverrideKey, true);
      debugPrint('🌐 [LocalizationService] Bahasa disetel manual ke: ${language.name.toUpperCase()}');
    } catch (e) {
      debugPrint('⚠️ [LocalizationService] Gagal menyimpan preferensi bahasa: $e');
    }
  }

  /// Kamus teks antarmuka (UI Strings Dictionary)
  String t(String key) {
    final Map<String, Map<AppLanguage, String>> strings = {
      // Header & Navigation
      'app_title': {
        AppLanguage.id: 'NiHao Kids',
        AppLanguage.en: 'NiHao Kids',
      },
      'select_grade': {
        AppLanguage.id: 'Pilih Jenjang Kelas',
        AppLanguage.en: 'Select Grade Level',
      },
      'subtitle_intro': {
        AppLanguage.id: 'Belajar Mandarin Seru bersama Maskot Panda Bao Bao 🐼✨',
        AppLanguage.en: 'Fun Mandarin Learning with Panda Bao Bao 🐼✨',
      },
      'total_vocab_badge': {
        AppLanguage.id: '260 Kosakata Standar YCT & Kurikulum SD',
        AppLanguage.en: '260 Standard YCT & Elementary Vocabularies',
      },

      // Buttons & Actions
      'watch_ad_bonus': {
        AppLanguage.id: 'Tonton Iklan (+50 Bambu)',
        AppLanguage.en: 'Watch Ad (+50 Bamboo)',
      },
      'panda_shop': {
        AppLanguage.id: 'Toko Panda',
        AppLanguage.en: 'Panda Shop',
      },
      'parents_corner': {
        AppLanguage.id: 'Pojok Orang Tua',
        AppLanguage.en: 'Parents Corner',
      },
      'listen_audio': {
        AppLanguage.id: 'DENGARKAN SUARA 🔊',
        AppLanguage.en: 'LISTEN AUDIO 🔊',
      },
      'stroke_order': {
        AppLanguage.id: 'URUTAN GORESAN ✍️',
        AppLanguage.en: 'STROKE ORDER ✍️',
      },
      'vocab_card': {
        AppLanguage.id: 'KARTU KATA 🎴',
        AppLanguage.en: 'VOCAB CARD 🎴',
      },
      'practice_writing': {
        AppLanguage.id: 'LATIHAN TULIS JARI 🎨',
        AppLanguage.en: 'FINGER TRACING 🎨',
      },
      'replay_strokes': {
        AppLanguage.id: 'Putar Ulang Goresan 🔄',
        AppLanguage.en: 'Replay Strokes 🔄',
      },
      'clear_canvas': {
        AppLanguage.id: 'Hapus Goresan 🧹',
        AppLanguage.en: 'Clear Canvas 🧹',
      },
      'stroke_count': {
        AppLanguage.id: 'Goresan',
        AppLanguage.en: 'Strokes',
      },
      'next': {
        AppLanguage.id: 'Berikutnya ▶',
        AppLanguage.en: 'Next ▶',
      },
      'previous': {
        AppLanguage.id: '◀ Sebelumnya',
        AppLanguage.en: '◀ Previous',
      },
      'quiz': {
        AppLanguage.id: 'Kuis 🎯',
        AppLanguage.en: 'Quiz 🎯',
      },

      // SnackBar & Notifications
      'audio_playing': {
        AppLanguage.id: '🔊 Memutar suara penutur asli:',
        AppLanguage.en: '🔊 Playing native speaker audio:',
      },
      'ad_buffering': {
        AppLanguage.id: 'Video iklan sedang disiapkan, silakan coba 5-10 detik lagi ya! ⏳',
        AppLanguage.en: 'Ad video is buffering, please wait 5-10 seconds! ⏳',
      },
      'ad_reward_success': {
        AppLanguage.id: '🎉 Hore! Kamu dapat +5 Bambu & +3 Bintang tersimpan permanen!',
        AppLanguage.en: '🎉 Yay! You earned +5 Bamboo & +3 Stars saved permanently!',
      },
      'ad_service_unavailable': {
        AppLanguage.id: 'Layanan iklan belum siap, periksa koneksi internet Anda.',
        AppLanguage.en: 'Ad service not ready, please check your internet connection.',
      },
      'level_locked': {
        AppLanguage.id: '🔒 Level ini masih terkunci! Kumpulkan bintang dengan menyelesaikan level sebelumnya.',
        AppLanguage.en: '🔒 Level locked! Complete previous levels to earn stars and unlock.',
      },
      'correct_answer': {
        AppLanguage.id: '🎉 Hebat sekali! Jawabanmu benar! ⭐ +1 Bintang',
        AppLanguage.en: '🎉 Awesome job! Correct answer! ⭐ +1 Star',
      },
      'wrong_answer': {
        AppLanguage.id: 'Ups! Kurang tepat, ayo coba dengarkan suaranya lagi ya!',
        AppLanguage.en: 'Oops! Not quite, listen to the pronunciation again!',
      },
      'bonus_stars_claimed': {
        AppLanguage.id: '🎁 +2 Bintang Tambahan Berhasil Diklaim!',
        AppLanguage.en: '🎁 +2 Extra Stars Claimed Successfully!',
      },
      'bamboo_shop_claimed': {
        AppLanguage.id: '🎁 +5 Bambu & +3 Bintang berhasil diklaim!',
        AppLanguage.en: '🎁 +5 Bamboo & +3 Stars claimed successfully!',
      },
      'level_bonus_stars': {
        AppLanguage.id: '🎉 Selamat! Bonus bintang untuk membuka level berikutnya!',
        AppLanguage.en: '🎉 Congrats! Bonus stars to unlock the next level!',
      },
      'next_level_unlocked': {
        AppLanguage.id: '🎉 Level berikutnya telah TERBUKA!',
        AppLanguage.en: '🎉 Next level is now UNLOCKED!',
      },
      'level_unlocked_success': {
        AppLanguage.id: '🎉 Hore! Level berhasil dibuka!',
        AppLanguage.en: '🎉 Yay! Level successfully unlocked!',
      },
      'how_to_unlock': {
        AppLanguage.id: 'Cara membuka level ini:',
        AppLanguage.en: 'How to unlock this level:',
      },
      'unlock_with_bamboo': {
        AppLanguage.id: 'Buka dengan 20 Bambu 🎋',
        AppLanguage.en: 'Unlock with 20 Bamboo 🎋',
      },
      'unlock_with_ad': {
        AppLanguage.id: 'Tonton Video Singkat (Buka Gratis) 🎬',
        AppLanguage.en: 'Watch Short Video (Unlock Free) 🎬',
      },
      'not_enough_bamboo': {
        AppLanguage.id: 'Bambu tidak cukup! Tonton video atau selesaikan kuis ya.',
        AppLanguage.en: 'Not enough bamboo! Watch video or complete quizzes.',
      },

      // Quiz
      'quiz_title': {
        AppLanguage.id: 'Kuis NiHao Kids 🎯',
        AppLanguage.en: 'NiHao Kids Quiz 🎯',
      },
      'quiz_prompt': {
        AppLanguage.id: 'Apa arti dari karakter ini?',
        AppLanguage.en: 'What does this character mean?',
      },
      'quiz_completed': {
        AppLanguage.id: 'Latihan Selesai!',
        AppLanguage.en: 'Quiz Completed!',
      },
      'quiz_cheer': {
        AppLanguage.id: 'Hore! Kamu hebat sekali! 🌟',
        AppLanguage.en: 'Hurray! You did great! 🌟',
      },
      'quiz_bonus_stars_btn': {
        AppLanguage.id: 'Tonton Video (Bintang +2) 🎁',
        AppLanguage.en: 'Watch Video (+2 Stars) 🎁',
      },
      'quiz_back_to_map': {
        AppLanguage.id: 'Kembali ke Peta 🗺️',
        AppLanguage.en: 'Back to Map 🗺️',
      },
      'quiz_next': {
        AppLanguage.id: 'Lanjut ➡️',
        AppLanguage.en: 'Next ➡️',
      },
      'quiz_see_results': {
        AppLanguage.id: 'Lihat Hasil! 🏆',
        AppLanguage.en: 'See Results! 🏆',
      },
      // Stamina Gate & Auto-Ad Break
      'stamina_empty_title': {
        AppLanguage.id: 'Bambu Habis! 🎋',
        AppLanguage.en: 'Out of Bamboo! 🎋',
      },
      'stamina_empty_desc': {
        AppLanguage.id: 'Bao Bao butuh 1 energi bambu untuk kuis! Tonton video singkat untuk isi ulang +5 Bambu & langsung lanjut kuis?',
        AppLanguage.en: 'Bao Bao needs 1 bamboo energy for quiz! Watch a short video to refill +5 Bamboo and start quiz immediately?',
      },
      'watch_ad_refill_btn': {
        AppLanguage.id: 'Tonton Video & Lanjut Kuis 🎬 (+5 🎋)',
        AppLanguage.en: 'Watch Video & Start Quiz 🎬 (+5 🎋)',
      },
      'stamina_used_toast': {
        AppLanguage.id: '🎋 -1 Energi Bambu digunakan untuk Kuis!',
        AppLanguage.en: '🎋 -1 Bamboo energy used for Quiz!',
      },
      'later_btn': {
        AppLanguage.id: 'Nanti Saja',
        AppLanguage.en: 'Later',
      },
      'water_break_title': {
        AppLanguage.id: 'Istirahat Minum Air Dulu Ya! 🐼💧',
        AppLanguage.en: 'Time for a Quick Water Break! 🐼💧',
      },
      'water_break_desc': {
        AppLanguage.id: 'Bao Bao bangga padamu! Bersiap dalam sekejap...',
        AppLanguage.en: 'Bao Bao is proud of you! Getting ready in a moment...',
      },
      'level1_starter_bamboo': {
        AppLanguage.id: '🎁 Bonus Pemula: +5 Bambu Energi Kuis!',
        AppLanguage.en: '🎁 Starter Bonus: +5 Bamboo Quiz Energy!',
      },

      // Shop & Wardrobe
      'wardrobe_title': {
        AppLanguage.id: 'Lemari Kostum Panda Bao Bao',
        AppLanguage.en: 'Panda Bao Bao Wardrobe',
      },
      'panda_ready_style': {
        AppLanguage.id: 'Panda Bao Bao siap bergaya!',
        AppLanguage.en: 'Panda Bao Bao is ready in style!',
      },
      'parents_corner_shop_btn': {
        AppLanguage.id: 'Pojok Orang Tua: Bebas Iklan & Top Up Bambu ➔',
        AppLanguage.en: 'Parents Corner: Ad-Free & Top Up Bamboo ➔',
      },
      'not_enough_bamboo_title': {
        AppLanguage.id: 'Bambu Kurang!',
        AppLanguage.en: 'Need More Bamboo!',
      },
      'free_video_btn': {
        AppLanguage.id: 'Iklan Gratis (+5 🎋)',
        AppLanguage.en: 'Free Video (+5 🎋)',
      },
      'top_up_btn': {
        AppLanguage.id: 'Top Up 👨‍👩‍👧',
        AppLanguage.en: 'Top Up 👨‍👩‍👧',
      },
      'bamboo_currency': {
        AppLanguage.id: 'Bambu',
        AppLanguage.en: 'Bamboo',
      },
      'feed_panda': {
        AppLanguage.id: 'Beri Makan Panda (-10 🎋)',
        AppLanguage.en: 'Feed Panda (-10 🎋)',
      },
      'equipped': {
        AppLanguage.id: 'Dipakai',
        AppLanguage.en: 'Equipped',
      },
      'equip': {
        AppLanguage.id: 'Pasang',
        AppLanguage.en: 'Equip',
      },
      'buy': {
        AppLanguage.id: 'Beli',
        AppLanguage.en: 'Buy',
      },
      'owned': {
        AppLanguage.id: 'Sudah Dimiliki',
        AppLanguage.en: 'Owned',
      },
      'free_premium': {
        AppLanguage.id: '👑 Eksklusif Bao Bao Premium',
        AppLanguage.en: '👑 Exclusive Bao Bao Premium',
      },
      'not_enough_bamboo': {
        AppLanguage.id: 'Bambu tidak cukup! Tonton video atau beli di Pojok Orang Tua.',
        AppLanguage.en: 'Not enough bamboo! Watch video or visit Parents Corner.',
      },

      // Parental Gate & Billing
      'parental_gate_title': {
        AppLanguage.id: 'Pojok Orang Tua (Parental Gate)',
        AppLanguage.en: 'Parents Corner (Parental Gate)',
      },
      'parental_gate_prompt': {
        AppLanguage.id: 'Tolong selesaikan soal matematika berikut untuk melanjutkan:',
        AppLanguage.en: 'Please solve the following math problem to continue:',
      },
      'parental_gate_adult_desc': {
        AppLanguage.id: 'Halaman ini khusus untuk orang dewasa. Tanyakan pada orang tua atau selesaikan soal berikut:',
        AppLanguage.en: 'This page is for parents and adults only. Please solve the math problem below:',
      },
      'write_answer_hint': {
        AppLanguage.id: 'Tulis Jawaban',
        AppLanguage.en: 'Type Answer',
      },
      'continue_btn': {
        AppLanguage.id: 'Lanjutkan ➔',
        AppLanguage.en: 'Continue ➔',
      },
      'enter_answer_error': {
        AppLanguage.id: 'Masukkan jawaban Anda.',
        AppLanguage.en: 'Please enter your answer.',
      },
      'math_error': {
        AppLanguage.id: 'Jawaban salah. Akses pembelian dibatalkan.',
        AppLanguage.en: 'Incorrect answer. Purchase access cancelled.',
      },
      'parental_gate_error': {
        AppLanguage.id: 'Jawaban salah, silakan coba lagi.',
        AppLanguage.en: 'Incorrect answer, please try again.',
      },
      'premium_badge': {
        AppLanguage.id: 'Paket Bao Bao Premium Aktif (Bebas Iklan)',
        AppLanguage.en: 'Bao Bao Premium Active (No Ads)',
      },
      'buy_premium_btn': {
        AppLanguage.id: 'Beli Bao Bao Premium (Rp49.000)',
        AppLanguage.en: 'Buy Bao Bao Premium (\$3.99)',
      },
      'cancel': {
        AppLanguage.id: 'Batal',
        AppLanguage.en: 'Cancel',
      },
      'confirm': {
        AppLanguage.id: 'Konfirmasi',
        AppLanguage.en: 'Confirm',
      },

      // Tones
      'tone_1': {
        AppLanguage.id: 'Nada 1 (Datar Tinggi)',
        AppLanguage.en: '1st Tone (High Flat)',
      },
      'tone_2': {
        AppLanguage.id: 'Nada 2 (Naik)',
        AppLanguage.en: '2nd Tone (Rising)',
      },
      'tone_3': {
        AppLanguage.id: 'Nada 3 (Turun-Naik)',
        AppLanguage.en: '3rd Tone (Dipping)',
      },
      'tone_4': {
        AppLanguage.id: 'Nada 4 (Turun Cepat)',
        AppLanguage.en: '4th Tone (Falling)',
      },
      'tone_0': {
        AppLanguage.id: 'Nada Netral (Ringan)',
        AppLanguage.en: 'Neutral Tone (Light)',
      },
    };

    final entry = strings[key];
    if (entry == null) return key;
    return entry[currentLanguage] ?? entry[AppLanguage.id] ?? key;
  }
}
