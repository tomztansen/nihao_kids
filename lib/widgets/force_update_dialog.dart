import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import '../services/update_service.dart';
import 'kid_button.dart';
import 'panda_avatar.dart';

class ForceUpdateDialog extends StatefulWidget {
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
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  bool _isDownloading = false;
  bool _isInstalling = false;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  StreamSubscription<DownloadProgress>? _downloadSub;

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  void _startInAppUpdate() {
    final url = widget.updateInfo.apkDownloadUrl.isNotEmpty
        ? widget.updateInfo.apkDownloadUrl
        : AppConfig.fallbackApkUrl;

    setState(() {
      _isDownloading = true;
      _isInstalling = false;
      _progress = 0.0;
      _receivedBytes = 0;
      _totalBytes = 0;
      _errorMessage = null;
    });

    _downloadSub?.cancel();
    _downloadSub = UpdateService().downloadApk(downloadUrl: url).listen(
      (event) async {
        if (event.error != null) {
          setState(() {
            _isDownloading = false;
            _isInstalling = false;
            _errorMessage = event.error;
          });
        } else if (event.isCompleted) {
          setState(() {
            _progress = 1.0;
            _isInstalling = true;
          });

          // Memicu Android Package Installer langsung di atas aplikasi
          final installResult = await UpdateService().installDownloadedApk();
          if (installResult.type != ResultType.done) {
            setState(() {
              _isDownloading = false;
              _isInstalling = false;
              _errorMessage = installResult.message.isNotEmpty
                  ? 'Izin instalasi: ${installResult.message}'
                  : 'Gagal membuka installer. Silakan coba lagi.';
            });
          }
        } else {
          setState(() {
            _progress = event.progress;
            _receivedBytes = event.receivedBytes;
            _totalBytes = event.totalBytes;
          });
        }
      },
      onError: (err) {
        setState(() {
          _isDownloading = false;
          _isInstalling = false;
          _errorMessage = 'Terjadi kesalahan jaringan: $err';
        });
      },
    );
  }

  void _openManualFallback() {
    final url = widget.updateInfo.webDownloadPage.isNotEmpty
        ? widget.updateInfo.webDownloadPage
        : AppConfig.webDownloadPage;
    UpdateService().openUpdateUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).clamp(0, 100).toInt();
    final receivedMB = (_receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = _totalBytes > 0 ? (_totalBytes / (1024 * 1024)).toStringAsFixed(1) : '...';

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
                  PandaAvatar(
                    size: 90,
                    mood: _isInstalling
                        ? PandaMood.cheering
                        : (_isDownloading ? PandaMood.thinking : PandaMood.happy),
                  ),
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
                    child: Text(_isInstalling ? '✨' : '🚀', style: const TextStyle(fontSize: 20)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Judul Dialog
              Text(
                _isInstalling
                    ? 'Memasang Pembaruan... ✨'
                    : (_isDownloading
                        ? 'Mengunduh Pembaruan... 🚀'
                        : (widget.updateInfo.title.isNotEmpty
                            ? widget.updateInfo.title
                            : 'Pembaruan Wajib Tersedia! 🚀')),
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
                  'Versi Baru: v${widget.updateInfo.latestVersion} (Saat ini: v${AppConfig.appVersion})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Jika sedang mengunduh: Tampilkan progress bar & byte counter
              if (_isDownloading || _isInstalling) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 14,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondaryGreen),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isInstalling ? '100% Selesai' : '$percent%',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.pandaBlack),
                    ),
                    Text(
                      _isInstalling ? 'Membuka Installer...' : '$receivedMB MB / $totalMB MB',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isInstalling
                              ? 'Ketuk "Update" pada jendela Android untuk memperbarui.'
                              : 'Aplikasi sedang mengunduh di latar dalam aplikasi. Jangan tutup layar ini ya!',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Pesan Penjelasan
                Text(
                  widget.updateInfo.message.isNotEmpty
                      ? widget.updateInfo.message
                      : 'Versi terbaru NiHao Kids telah dirilis. Anda wajib memperbarui aplikasi untuk melanjutkan belajar.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],

              // Jika ada pesan kesalahan
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Tombol Aksi Utama
              if (!_isDownloading && !_isInstalling) ...[
                KidButton(
                  text: '⚡ Update Otomatis Sekarang',
                  color: AppColors.secondaryGreen,
                  shadowColor: const Color(0xFF2E7D32),
                  onPressed: _startInAppUpdate,
                ),
                const SizedBox(height: 10),

                // Tombol Alternatif jika ingin via browser
                TextButton(
                  onPressed: _openManualFallback,
                  child: const Text(
                    '🌐 Unduh Manual di Browser / Scan QR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
