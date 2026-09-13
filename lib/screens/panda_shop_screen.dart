import 'package:flutter/material.dart';
import '../services/admob_service.dart';
import '../services/reward_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kid_button.dart';
import '../widgets/panda_avatar.dart';
import '../widgets/parental_gate_dialog.dart';
import 'parent_store_dialog.dart';

class PandaShopScreen extends StatefulWidget {
  const PandaShopScreen({Key? key}) : super(key: key);

  @override
  State<PandaShopScreen> createState() => _PandaShopScreenState();
}

class ShopItem {
  final String id;
  final String name;
  final String icon;
  final int cost;
  final String description;

  const ShopItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.cost,
    required this.description,
  });
}

class _PandaShopScreenState extends State<PandaShopScreen> {
  String _currentHat = 'none';
  final List<String> _ownedHats = ['none'];

  final List<ShopItem> _items = const [
    ShopItem(id: 'cowboy', name: 'Topi Koboi Cilik', icon: '🤠', cost: 100, description: 'Biasa • Bao Bao jadi petualang tangguh!'),
    ShopItem(id: 'grad', name: 'Topi Sarjana Pintar', icon: '🎓', cost: 300, description: 'Keren • Juara kelas bahasa Mandarin!'),
    ShopItem(id: 'glasses', name: 'Kacamata Bintang', icon: '🕶️', cost: 300, description: 'Keren • Gaya santai membaca Hanzi!'),
    ShopItem(id: 'astronaut', name: 'Helm Astronot Cilik', icon: '🚀', cost: 700, description: 'Langka • Menjelajah luar angkasa!'),
    ShopItem(id: 'crown', name: 'Mahkota Kaisar Emas', icon: '👑', cost: 1500, description: 'Legendary • Eksklusif Bao Bao Premium!'),
  ];

  void _openParentStore() {
    ParentalGateDialog.show(
      context,
      onPassed: () {
        ParentStoreDialog.show(
          context,
          onPurchaseCompleted: () {
            setState(() {});
          },
        );
      },
    );
  }

  void _buyItem(ShopItem item) async {
    final isPremium = RewardService().isPremium;
    final isFreeForPremium = item.id == 'crown' && isPremium;

    if (_ownedHats.contains(item.id) || isFreeForPremium) {
      setState(() => _currentHat = item.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.secondaryGreen, content: Text('Panda Bao Bao memakai ${item.name}!')),
      );
      return;
    }

    // Periksa apakah bambu cukup
    final success = await RewardService().spendBamboo(item.cost);
    if (success) {
      setState(() {
        _ownedHats.add(item.id);
        _currentHat = item.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.secondaryGreen, content: Text('🎉 Hore! Berhasil membeli ${item.name}!')),
      );
    } else {
      // Bambu tidak cukup -> Tawarkan nonton iklan AdMob atau beli lewat Orang Tua
      _showOutOfBambooDialog(item);
    }
  }

  void _showOutOfBambooDialog(ShopItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('🎋', style: TextStyle(fontSize: 28)),
            SizedBox(width: 8),
            Text('Bambu Kurang!'),
          ],
        ),
        content: Text(
          'Kamu butuh ${item.cost} bambu untuk membeli ${item.name}.\n\nPilih cara menambah bambu:',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              AdMobService().showRewardedAd(
                onUserEarnedReward: () async {
                  await RewardService().addRewardFromAd(bambooReward: 5, starReward: 3);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.secondaryGreen,
                      content: Text('🎁 +5 Bambu & +3 Bintang berhasil diklaim!'),
                    ),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryYellow,
              foregroundColor: AppColors.pandaBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.play_circle_fill, color: Colors.deepOrange, size: 18),
            label: const Text('Iklan Gratis (+5 🎋)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _openParentStore();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.skyBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.family_restroom, size: 18),
            label: const Text('Top Up 👨‍👩‍👧', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bamboo = RewardService().bamboo;
    final isPremium = RewardService().isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lemari Kostum Bao Bao 🐼'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondaryGreen, width: 2),
            ),
            child: Row(
              children: [
                const Text('🎋', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text('$bamboo', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preview Panda with selected Hat
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.none,
                    children: [
                      const PandaAvatar(size: 100, mood: PandaMood.excited),
                      if (_currentHat != 'none')
                        Positioned(
                          top: -15,
                          child: Text(
                            _items.firstWhere((i) => i.id == _currentHat).icon,
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Panda Bao Bao siap bergaya!',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.pandaBlack),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('PREMIUM 👑', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Parent Store Entry Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openParentStore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF3E0),
                        foregroundColor: const Color(0xFFE65100),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFFFB74D), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Text('👨‍👩‍👧', style: TextStyle(fontSize: 18)),
                      label: const Text(
                        'Pojok Orang Tua: Bebas Iklan & Top Up Bambu ➔',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Item List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final isFreeForPrem = item.id == 'crown' && isPremium;
                  final isOwned = _ownedHats.contains(item.id) || isFreeForPrem;
                  final isEquipped = _currentHat == item.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isEquipped ? AppColors.secondaryGreen : Colors.black12,
                        width: isEquipped ? 2.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(item.icon, style: const TextStyle(fontSize: 34)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                item.description,
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Text('🎋 ', style: TextStyle(fontSize: 11)),
                                  Text(
                                    isFreeForPrem ? 'Eksklusif Premium' : '${item.cost} Bambu',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isOwned ? Colors.grey : AppColors.secondaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _buyItem(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEquipped
                                ? Colors.grey[300]
                                : isOwned
                                    ? AppColors.skyBlue
                                    : AppColors.primaryYellow,
                            foregroundColor: AppColors.pandaBlack,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            isEquipped
                                ? 'Dipakai'
                                : isOwned
                                    ? 'Pasang'
                                    : 'Beli 🎋',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
