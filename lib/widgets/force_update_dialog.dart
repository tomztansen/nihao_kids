import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../services/update_service.dart';
import 'kid_button.dart';
import 'panda_avatar.dart';

class ForceUpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const ForceUpdateDialog({
    Key? key,
    required this.updateInfo,
  }) : super(key: key);

  static Future<void> show(BuildContext context, UpdateInfo updateInfo) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ForceUpdateDialog(updateInfo: updateInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Menolak tombol kembali Android (Wajib Update)
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Panda Badge dengan ikon roket
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const PandaAvatar(size: 90),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryYellow,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Text('🚀', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Judul Dialog
              Text(
                updateInfo.title.isNotEmpty ? updateInfo.title : 'Pembaruan Wajib Tersedia! 🚀',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pandaBlack,
                ),
              ),
              const SizedBox(height: 8),

              // Chip Versi Baru
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text(
                  'Versi Baru: v${updateInfo.latestVersion} (Saat ini: v${AppConfig.appVersion})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Pesan Penjelasan
              Text(
                updateInfo.message.isNotEmpty
                    ? updateInfo.message
                    : 'Versi terbaru NiHao Kids telah dirilis. Anda wajib memperbarui aplikasi untuk melanjutkan belajar.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Utama: Unduh APK Sekarang
              KidButton(
                text: '📥 Unduh & Pasang Sekarang',
                color: AppColors.secondaryGreen,
                shadowColor: const Color(0xFF2E7D32),
                onPressed: () {
                  final url = updateInfo.apkDownloadUrl.isNotEmpty
                      ? updateInfo.apkDownloadUrl
                      : AppConfig.fallbackApkUrl;
                  UpdateService().openUpdateUrl(url);
                },
              ),
              const SizedBox(height: 10),

              // Tombol Sekunder: Buka Halaman Web / Scan QR
              TextButton(
                onPressed: () {
                  final url = updateInfo.webDownloadPage.isNotEmpty
                      ? updateInfo.webDownloadPage
                      : AppConfig.webDownloadPage;
                  UpdateService().openUpdateUrl(url);
                },
                child: const Text(
                  '🌐 Buka Halaman Unduh / Scan QR Code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
