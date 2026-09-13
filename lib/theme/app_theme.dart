import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryYellow = Color(0xFFFFCA28);
  static const Color secondaryGreen = Color(0xFF66BB6A);
  static const Color pandaBlack = Color(0xFF263238);
  static const Color skyBlue = Color(0xFF4FC3F7);
  static const Color sweetPink = Color(0xFFFF80AB);
  static const Color coralOrange = Color(0xFFFF7043);
  static const Color backgroundLight = Color(0xFFF9FBE7); // Lembut di mata anak
  static const Color cardSurface = Colors.white;

  // Tone Colors (Pedagogi Standar Belajar Mandarin untuk Anak)
  static const Color tone1 = Color(0xFFE53935); // Merah (Datar / Tinggi)
  static const Color tone2 = Color(0xFFFFB300); // Kuning/Oranye (Naik)
  static const Color tone3 = Color(0xFF43A047); // Hijau (Turun-Naik)
  static const Color tone4 = Color(0xFF1E88E5); // Biru (Turun Tegas)
  static const Color toneNeutral = Color(0xFF78909C); // Abu-abu

  static Color getToneColor(int tone) {
    switch (tone) {
      case 1:
        return tone1;
      case 2:
        return tone2;
      case 3:
        return tone3;
      case 4:
        return tone4;
      default:
        return toneNeutral;
    }
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.secondaryGreen,
        primary: AppColors.secondaryGreen,
        secondary: AppColors.primaryYellow,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.pandaBlack),
        titleTextStyle: TextStyle(
          color: AppColors.pandaBlack,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
