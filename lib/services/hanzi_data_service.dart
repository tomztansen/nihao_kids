import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HanziDataService {
  static final HanziDataService _instance = HanziDataService._internal();
  factory HanziDataService() => _instance;
  HanziDataService._internal();

  Map<String, dynamic>? _hanziData;
  String? _hanziWriterJs;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  String? get hanziWriterJs => _hanziWriterJs;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      if (_hanziData == null) {
        final jsonStr = await rootBundle.loadString('assets/hanzi_data.json');
        _hanziData = jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      if (_hanziWriterJs == null) {
        _hanziWriterJs = await rootBundle.loadString('assets/hanzi_writer.min.js');
      }
      _isInitialized = true;
      debugPrint('HanziDataService: loaded ${_hanziData?.length ?? 0} characters offline.');
    } catch (e) {
      debugPrint('HanziDataService init error: $e');
    }
  }

  Map<String, dynamic>? getCharData(String char) {
    if (_hanziData == null) return null;
    return _hanziData![char] as Map<String, dynamic>?;
  }

  String getCharDataJson(String char) {
    final data = getCharData(char);
    if (data == null) return 'null';
    return jsonEncode(data);
  }
}
