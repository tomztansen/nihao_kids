import 'package:flutter/material.dart';
import '../services/reward_service.dart';
import '../theme/app_theme.dart';

/// Modal Toko Khusus Orang Tua (Google Play In-App Purchase)
class ParentStoreDialog extends StatefulWidget {
  final VoidCallback onPurchaseCompleted;

  const ParentStoreDialog({Key? key, required this.onPurchaseCompleted}) : super(key: key);

  static Future<void> show(BuildContext context, {required VoidCallback onPurchaseCompleted}) {
    return showDialog(
      context: context,
      builder: (_) => ParentStoreDialog(onPurchaseCompleted: onPurchaseCompleted),
    );
  }

  @override
  State<ParentStoreDialog> createState() => _ParentStoreDialogState();
}

class _ParentStoreDialogState extends State<ParentStoreDialog> {
  /// =========================================================================
  /// KONFIGURASI SAKLAR FITUR PEMBAYARAN
  /// =========================================================================
  /// [isPaymentReady]
  /// - `false` : (Mode Saat Ini) Fitur pembayaran ditandai "Masih Dalam Pengembangan".
  ///             Semua tombol pembelian akan menampilkan modal pemberitahuan ramah
  ///             bahwa sistem pembayaran sedang disiapkan.
  /// - `true`  : Fitur pembayaran aktif.
  ///
  /// 💡 JIKA NANTI SUDAH SIAP DITERAPKAN:
  /// 1. Ubah nilai di bawah menjadi `true`.
  /// 2. Pasang alur pembayaran yang Anda inginkan (WhatsApp / Kode Voucher / Gateway)
  ///    pada fungsi [_buyPremium] & [_buyBambooPack].
  static const bool isPaymentReady = false;

  bool _loading = false;

  /// Handler perantara ketika orang tua menekan tombol pembayaran
  void _onPurchaseTapped({
    required String productName,
    required VoidCallback onProceed,
  }) {
    if (!isPaymentReady) {
      _showUnderDevelopmentDialog(productName);
      return;
    }
    // Jika sistem pembayaran sudah diaktifkan (true), lanjutkan proses pembelian:
    onProceed();
  }

  /// Dialog informasi ramah bahwa fitur pembayaran masih dalam pengembangan
  void _showUnderDevelopmentDialog(String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('🛠️', style: TextStyle(fontSize: 26)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Masih Dalam Pengembangan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pilihan: $productName',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF4E342E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Fitur pembayaran resmi saat ini masih dalam tahap pengembangan dan akan segera hadir pada pembaruan mendatang.\n\nSaat ini anak Anda tetap dapat menikmati seluruh materi belajar secara 100% gratis!\n\nTerima kasih banyak atas antusiasme dan dukungan Ayah & Bunda! ❤️',
              style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF37474F)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Baik, Saya Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _buyPremium() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600)); // Simulasi koneksi Play Billing
    await RewardService().purchasePremium();
    setState(() => _loading = false);

    if (mounted) {
      widget.onPurchaseCompleted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.secondaryGreen,
          content: Text('🎉 Selamat! Paket Bao Bao Premium berhasil diaktifkan selamanya!'),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _buyBambooPack(int amount, String price) async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    await RewardService().purchaseBambooPack(amount);
    setState(() => _loading = false);

    if (mounted) {
      widget.onPurchaseCompleted();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.secondaryGreen,
          content: Text('🎋 Berhasil membeli +$amount Bambu ($price)!'),
        ),
      );
    }
  }

  void _restorePurchases() async {
    setState(() => _loading = true);
    final restored = await RewardService().restorePurchases();
    setState(() => _loading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: restored ? AppColors.secondaryGreen : Colors.blueGrey,
          content: Text(restored
              ? '✅ Pembelian Bao Bao Premium berhasil dipulihkan!'
              : 'Tidak ditemukan riwayat pembelian sebelumnya pada akun ini.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrem = RewardService().isPremium;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text('👨‍👩‍👧', style: TextStyle(fontSize: 26)),
                      SizedBox(width: 8),
                      Text(
                        'Pojok Orang Tua',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Banner Pemberitahuan: Masih Dalam Pengembangan
              if (!isPaymentReady)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFB300), width: 1.2),
                  ),
                  child: const Row(
                    children: [
                      Text('🛠️', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fitur pembayaran saat ini masih dalam tahap pengembangan (Segera Hadir).',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Hero Card: Bao Bao Premium
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFB300), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Text('👑', style: TextStyle(fontSize: 24)),
                            SizedBox(width: 6),
                            Text(
                              'Bao Bao Premium',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF4E342E)),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8F00),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Sekali Bayar',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Hapus semua iklan selamanya\n• Bonus langsung +100 Bambu 🎋\n• Kostum Eksklusif: Mahkota Kaisar Emas 👑\n• Bonus +20% XP Belajar & Lencana Emas',
                      style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF4E342E)),
                    ),
                    const SizedBox(height: 12),
                    if (isPrem)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          '✅ Paket Premium Telah Aktif',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: _loading
                            ? null
                            : () => _onPurchaseTapped(
                                  productName: 'Paket Bao Bao Premium (Rp49.000)',
                                  onProceed: _buyPremium,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPaymentReady ? const Color(0xFFD84315) : const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Rp49.000 ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            Text(
                              isPaymentReady ? '(Hemat Rp30.000)' : '(Dalam Pengembangan)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isPaymentReady ? const Color(0xFFFFCCBC) : const Color(0xFFFFE082),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Section Top Up Bambu
              const Row(
                children: [
                  Text('🎋', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 6),
                  Text(
                    'Paket Top Up Bambu Panda',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 4 Paket Top Up
              _buildTopUpTile('Mini: 100 Bambu', 'Rp10.000', '100/bambu', 100, const Color(0xFF81C784)),
              const SizedBox(height: 8),
              _buildTopUpTile('Small: 250 Bambu', 'Rp20.000', '80/bambu', 250, const Color(0xFF4CAF50)),
              const SizedBox(height: 8),
              _buildTopUpTile('Large: 600 Bambu (Populer)', 'Rp45.000', '75/bambu', 600, const Color(0xFF2E7D32)),
              const SizedBox(height: 8),
              _buildTopUpTile('Mega: 1.500 Bambu (Paling Hemat)', 'Rp99.000', '66/bambu', 1500, const Color(0xFF1B5E20)),

              const SizedBox(height: 14),

              // Restore Button & Transparency Note
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    if (!isPaymentReady) {
                      _showUnderDevelopmentDialog('Pulihkan Pembelian');
                      return;
                    }
                    _restorePurchases();
                  },
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.blueGrey),
                  label: const Text(
                    'Pulihkan Pembelian (Restore)',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Text(
                isPaymentReady
                    ? '🔒 Diproses resmi lewat Google Play Billing. Materi belajar anak 100% gratis tanpa pembelian ini.'
                    : '🛠️ Fitur pembayaran masih dalam tahap pengembangan. Seluruh materi belajar anak 100% gratis!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopUpTile(String name, String price, String rate, int amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('Rp$rate', style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
            ],
          ),
          ElevatedButton(
            onPressed: _loading
                ? null
                : () => _onPurchaseTapped(
                      productName: '$name ($price)',
                      onProceed: () => _buyBambooPack(amount, price),
                    ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaymentReady ? color : Colors.blueGrey.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              elevation: 0,
            ),
            child: Text(
              isPaymentReady ? price : '$price • Segera',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
