import 'package:flutter/material.dart';
import '../models/models.dart';
import 'curriculum_meihua_lower.dart';
import 'curriculum_meihua_upper.dart';
import 'curriculum_xingxing.dart';

class CurriculumData {
  static final List<GradeLevel> gradeLevels = [
    const GradeLevel(
      grade: SchoolGrade.paud,
      title: 'Bintang Cilik (PAUD)',
      titleEn: 'Little Stars (Pre-K)',
      subtitle: 'Piktogram Visual, Bunyi Nada & Angka Jari (3-4 Thn)',
      subtitleEn: 'Visual Pictograms, Tone Sounds & Finger Numbers (3-4 Yrs)',
      ageRange: '3 - 4 Thn',
      ageRangeEn: '3 - 4 Yrs',
      primaryColor: Color(0xFFFFB300),
      secondaryColor: Color(0xFFFFF3E0),
      icon: '🐣',
    ),
    const GradeLevel(
      grade: SchoolGrade.tk,
      title: 'Tunas Ceria (TK A/B)',
      titleEn: 'Happy Sprouts (Kindergarten)',
      subtitle: 'Pinyin, Buah, Sayur, Hewan & Perintah Kelas (5-6 Thn)',
      subtitleEn: 'Pinyin, Fruits, Veggies, Animals & Classroom (5-6 Yrs)',
      ageRange: '5 - 6 Thn',
      ageRangeEn: '5 - 6 Yrs',
      primaryColor: Color(0xFF4CAF50),
      secondaryColor: Color(0xFFE8F5E9),
      icon: '🎈',
    ),
    const GradeLevel(
      grade: SchoolGrade.sdLower,
      title: 'Penjelajah (SD 1 - 3)',
      titleEn: 'Explorers (Grade 1 - 3)',
      subtitle: 'Kurikulum SD: Jam, Hari, Benda Kelas & YCT Level 1',
      subtitleEn: 'Elementary School: Clock, Days, School Items & YCT 1',
      ageRange: '7 - 9 Thn',
      ageRangeEn: '7 - 9 Yrs',
      primaryColor: Color(0xFF29B6F6),
      secondaryColor: Color(0xFFE1F5FE),
      icon: '🐼',
    ),
    const GradeLevel(
      grade: SchoolGrade.sdUpper,
      title: 'Pendekar YCT (SD 4 - 6)',
      titleEn: 'YCT Warriors (Grade 4 - 6)',
      subtitle: 'Percakapan Harian, Hobi, Arah, Belanja & YCT Level 2',
      subtitleEn: 'Conversations, Hobbies, Directions, Shopping & YCT 2',
      ageRange: '10 - 12 Thn',
      ageRangeEn: '10 - 12 Yrs',
      primaryColor: Color(0xFFAB47BC),
      secondaryColor: Color(0xFFF3E5F5),
      icon: '🐉',
    ),
  ];

  static List<LessonTopic> getLessonsForGrade(SchoolGrade grade) {
    switch (grade) {
      case SchoolGrade.paud:
        return XingxingCurriculum.getPaudLessons();
      case SchoolGrade.tk:
        return XingxingCurriculum.getTkLessons();
      case SchoolGrade.sdLower:
        return MeiHuaLowerCurriculum.getLessons();
      case SchoolGrade.sdUpper:
        return MeiHuaUpperCurriculum.getLessons();
    }
  }

  /// Total seluruh kosakata yang tersedia
  static int getTotalVocabCount() {
    int count = 0;
    for (var grade in SchoolGrade.values) {
      for (var lesson in getLessonsForGrade(grade)) {
        count += lesson.vocabs.length;
      }
    }
    return count;
  }

  /// Total seluruh unit pembelajaran
  static int getTotalUnitsCount() {
    int count = 0;
    for (var grade in SchoolGrade.values) {
      count += getLessonsForGrade(grade).length;
    }
    return count;
  }
}
