import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class LanguageSwitchButton extends StatelessWidget {
  final bool compact;

  const LanguageSwitchButton({Key? key, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: loc.languageNotifier,
      builder: (context, lang, _) {
        final isEn = lang == AppLanguage.en;

        return Tooltip(
          message: loc.isManualOverride
              ? (isEn ? 'Tap to switch to ID, hold to reset to Auto' : 'Ketuk ganti EN, tahan untuk reset Otomatis')
              : (isEn ? 'Smart Auto-Detect (System EN). Tap to switch' : 'Smart Auto-Detect (Sistem ID). Ketuk ganti'),
          child: InkWell(
            onTap: () => loc.toggleLanguage(),
            onLongPress: () async {
              await loc.resetToAutoDetect();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF1E88E5),
                    content: Text(
                      loc.isEnglish
                          ? '🌐 Smart Auto-Detect: Following device language (${loc.currentLanguage.name.toUpperCase()})'
                          : '🌐 Smart Auto-Detect: Mengikuti bahasa sistem HP (${loc.currentLanguage.name.toUpperCase()})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 12,
                vertical: compact ? 4 : 6,
              ),
              decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEn ? const Color(0xFF1E88E5) : const Color(0xFFE53935),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEn ? '🇬🇧' : '🇮🇩',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  isEn ? 'EN' : 'ID',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isEn ? const Color(0xFF1565C0) : const Color(0xFFC62828),
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }
}
