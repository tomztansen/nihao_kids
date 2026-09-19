import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _voicePlayer = AudioPlayer();

  Future<void> playSuccess() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/sfx/success.wav'));
    } catch (e) {
      debugPrint('Audio SFX error: $e');
    }
  }

  Future<void> playClick() async {
    // Suara tombol dinonaktifkan sesuai preferensi pengguna
  }

  Future<void> playFanfare() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/sfx/fanfare.wav'));
    } catch (e) {
      debugPrint('Audio SFX error: $e');
    }
  }

  Future<void> playWrong() async {
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource('audio/sfx/wrong.wav'));
    } catch (e) {
      debugPrint('Audio SFX error: $e');
    }
  }

  Future<void> playHanziVoice(String vocabId, [String? pinyin]) async {
    try {
      final actualId = vocabId == '你好' ? 'p39' : vocabId;
      debugPrint('Voice: Pronouncing Mandarin -> $actualId ($pinyin)');
      await _voicePlayer.stop();
      await _voicePlayer.play(AssetSource('audio/words/$actualId.mp3'));
    } catch (e) {
      debugPrint('Voice Audio error: $e');
    }
  }

  void dispose() {
    _sfxPlayer.dispose();
    _voicePlayer.dispose();
  }
}
