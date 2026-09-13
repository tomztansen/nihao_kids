import 'package:flutter/material.dart';
import '../data/curriculum_data.dart';
import '../models/models.dart';
import '../services/admob_service.dart';
import '../services/audio_service.dart';
import '../services/reward_service.dart';
import '../theme/app_theme.dart';
import '../widgets/panda_avatar.dart';
import 'lesson_map_screen.dart';
import 'panda_shop_screen.dart';

class GradeSelectionScreen extends StatefulWidget {
  const GradeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<GradeSelectionScreen> createState() => _GradeSelectionScreenState();
}

class _GradeSelectionScreenState extends State<GradeSelectionScreen> {
  int get _bambooCount => RewardService().bamboo;
  int get _starsCount => RewardService().stars;

  void _watchAdForBamboo() {
    AdMobService().showRewardedAd(
      onUserEarnedReward: () async {
        await RewardService().addRewardFromAd(bambooReward: 5, starReward: 3);
        setState(() {}); // Refresh UI
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.secondaryGreen,
            content: Text(
              '🎉 Hore! Kamu dapat +5 Bambu & +3 Bintang tersimpan permanen!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  void _playPandaGreeting() {
    AudioService().playHanziVoice('你好', 'nǐ hǎo');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.primaryYellow,
        content: Text(
          '🔊 Panda Bao Bao: "Ni Hao! (你好)"',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pandaBlack),
        ),
      ),
    );
  }

  void _openPandaShop() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PandaShopScreen()),
    );
    setState(() {}); // Refresh saldo setelah berbelanja
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Bamboo, Watch Ad, Stars
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bamboo Counter (Clickable to open shop)
                  GestureDetector(
                    onTap: _openPandaShop,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.secondaryGreen, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text('🎋', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            '$_bambooCount',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.pandaBlack,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.add_circle, color: AppColors.secondaryGreen, size: 16),
                        ],
                      ),
                    ),
                  ),

                  // Rewarded Ad Button (COPPA Compliant)
                  ElevatedButton.icon(
                    onPressed: _watchAdForBamboo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryYellow,
                      foregroundColor: AppColors.pandaBlack,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.play_circle_fill, color: Colors.deepOrange, size: 18),
                    label: const Text(
                      'Bambu Gratis 🎁',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),

                  // Stars Counter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '$_starsCount',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.pandaBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Header Mascot with clickable sound
            GestureDetector(
              onTap: _playPandaGreeting,
              child: const PandaAvatar(
                size: 90,
                speechText: 'Ni Hao! Aku Bao Bao si Panda! 🐼\n(Sentuh aku untuk mendengar suara!)',
              ),
            ),
            const SizedBox(height: 6),

            // Action Buttons Row: Sound & Panda Wardrobe
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _playPandaGreeting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryYellow,
                        foregroundColor: AppColors.pandaBlack,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.amber, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.volume_up_rounded, size: 20),
                      label: const Text(
                        'Suara "Ni Hao!" 🔊',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openPandaShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.skyBlue,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFF0288D1), width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.checkroom_rounded, size: 20),
                      label: const Text(
                        'Kostum Panda 👗',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Title
            const Text(
              'NiHao Kids',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.pandaBlack,
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              'Pilih Kelas Sekolahmu:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            // Grade Level Cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemCount: CurriculumData.gradeLevels.length,
                itemBuilder: (context, index) {
                  final grade = CurriculumData.gradeLevels[index];
                  return _buildGradeCard(grade);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeCard(GradeLevel grade) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: grade.primaryColor.withOpacity(0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: grade.primaryColor.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LessonMapScreen(gradeLevel: grade),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: grade.secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      grade.icon,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            grade.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.pandaBlack,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: grade.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              grade.ageRange,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: grade.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        grade.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.black26,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
