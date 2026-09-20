import 'package:flutter/material.dart';
import '../services/localization_service.dart';

enum SchoolGrade {
  paud,    // PAUD & Nursery (Xingxing Series Starter) Usia 3-4 th
  tk,      // TK-A & TK-B (Xingxing Series Level 1-2) Usia 5-6 th
  sdLower, // SD Kelas 1 - 3 (Mei Hua Buku 1, 2, 3) Usia 7-9 th
  sdUpper, // SD Kelas 4 - 6 (Mei Hua Buku 4, 5, 6) Usia 10-12 th
}

class GradeLevel {
  final SchoolGrade grade;
  final String title;
  final String? titleEn;
  final String subtitle;
  final String? subtitleEn;
  final String ageRange;
  final String? ageRangeEn;
  final Color primaryColor;
  final Color secondaryColor;
  final String icon;

  const GradeLevel({
    required this.grade,
    required this.title,
    this.titleEn,
    required this.subtitle,
    this.subtitleEn,
    required this.ageRange,
    this.ageRangeEn,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });

  String get localizedTitle => LocalizationService().isEnglish ? (titleEn ?? title) : title;
  String get localizedSubtitle => LocalizationService().isEnglish ? (subtitleEn ?? subtitle) : subtitle;
  String get localizedAgeRange => LocalizationService().isEnglish ? (ageRangeEn ?? ageRange) : ageRange;
}

class VocabItem {
  final String id;
  final String hanzi;
  final String pinyin;
  final String meaningId; // Arti bahasa Indonesia
  final String? meaningEn; // Meaning in English
  final int tone; // 1, 2, 3, 4, or 0 (neutral)
  final String category;
  final String emoji;
  final String? exampleSentenceHanzi;
  final String? exampleSentencePinyin;
  final String? exampleSentenceId;
  final String? exampleSentenceEn;

  const VocabItem({
    required this.id,
    required this.hanzi,
    required this.pinyin,
    required this.meaningId,
    this.meaningEn,
    required this.tone,
    required this.category,
    required this.emoji,
    this.exampleSentenceHanzi,
    this.exampleSentencePinyin,
    this.exampleSentenceId,
    this.exampleSentenceEn,
  });

  String get meaning => LocalizationService().isEnglish ? (meaningEn ?? meaningId) : meaningId;
  String? get exampleSentence => LocalizationService().isEnglish ? (exampleSentenceEn ?? exampleSentenceId) : exampleSentenceId;
}

class LessonTopic {
  final String id;
  final SchoolGrade grade;
  final String title;
  final String? titleEn;
  final String subtitle;
  final String? subtitleEn;
  final String emoji;
  final Color themeColor;
  final List<VocabItem> vocabs;
  final int starsRequired;
  int starsEarned;
  bool isUnlocked;

  LessonTopic({
    required this.id,
    required this.grade,
    required this.title,
    this.titleEn,
    required this.subtitle,
    this.subtitleEn,
    required this.emoji,
    required this.themeColor,
    required this.vocabs,
    this.starsRequired = 0,
    this.starsEarned = 0,
    this.isUnlocked = false,
  });

  String get localizedTitle => LocalizationService().isEnglish ? (titleEn ?? title) : title;
  String get localizedSubtitle => LocalizationService().isEnglish ? (subtitleEn ?? subtitle) : subtitle;
}

class QuizQuestion {
  final String prompt;
  final String? audioTarget;
  final String? hanziTarget;
  final String correctAnswer;
  final List<String> options;
  final String emoji;

  const QuizQuestion({
    required this.prompt,
    this.audioTarget,
    this.hanziTarget,
    required this.correctAnswer,
    required this.options,
    required this.emoji,
  });
}
