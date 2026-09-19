import 'package:flutter/material.dart';
import '../data/curriculum_data.dart';
import '../data/curriculum_xingxing.dart';
import '../data/curriculum_meihua_lower.dart';
import '../data/curriculum_meihua_upper.dart';
import '../models/models.dart';
import '../services/admob_service.dart';
import '../services/localization_service.dart';
import '../services/reward_service.dart';
import '../theme/app_theme.dart';
import '../widgets/language_switch_button.dart';
import 'flashcard_screen.dart';

class LessonMapScreen extends StatefulWidget {
  final GradeLevel gradeLevel;

  const LessonMapScreen({Key? key, required this.gradeLevel}) : super(key: key);

  @override
  State<LessonMapScreen> createState() => _LessonMapScreenState();
}

class _LessonMapScreenState extends State<LessonMapScreen> {
  late List<LessonTopic> _lessons;
  int _totalGradeStars = 0;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  void _loadLessons() {
    _lessons = widget.gradeLevel.grade == SchoolGrade.paud
        ? XingxingCurriculum.getPaudLessons()
        : widget.gradeLevel.grade == SchoolGrade.tk
            ? XingxingCurriculum.getTkLessons()
            : widget.gradeLevel.grade == SchoolGrade.sdLower
                ? MeiHuaLowerCurriculum.getLessons()
                : MeiHuaUpperCurriculum.getLessons();

    _syncLessons();
  }

  void _syncLessons() {
    final reward = RewardService();

    // 1. Sinkronisasi bintang tiap level dan hitung total bintang kelas ini
    int totalStars = 0;
    for (final l in _lessons) {
      final savedStars = reward.getLessonStars(l.id);
      if (savedStars > 0) {
        l.starsEarned = savedStars;
      }
      totalStars += l.starsEarned;
    }
    _totalGradeStars = totalStars;

    // 2. Tentukan status unlock setiap level
    for (int i = 0; i < _lessons.length; i++) {
      final lesson = _lessons[i];
      // Level 1 dan Level 2 selalu terbuka sejak awal
      if (i == 0 || i == 1) {
        lesson.isUnlocked = true;
      } else {
        final prevLesson = _lessons[i - 1];
        final prevCompleted = prevLesson.starsEarned > 0;
        final metStarsReq = lesson.starsRequired > 0 && _totalGradeStars >= lesson.starsRequired;
        final explicitlyUnlocked = reward.isLessonUnlocked(lesson.id);

        if (prevCompleted || metStarsReq || explicitlyUnlocked || lesson.isUnlocked) {
          lesson.isUnlocked = true;
          if (!explicitlyUnlocked) {
            reward.unlockLesson(lesson.id);
          }
        }
      }
    }
  }

  void _onLessonTap(LessonTopic lesson, int index) {
    if (!lesson.isUnlocked) {
      _showUnlockModal(lesson, index);
      return;
    }

    final nextLessonId = (index + 1 < _lessons.length) ? _lessons[index + 1].id : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          lesson: lesson,
          nextLessonId: nextLessonId,
        ),
      ),
    ).then((_) {
      setState(() {
        _syncLessons();
      });
    });
  }

  void _showUnlockModal(LessonTopic lesson, int index) {
    final loc = LocalizationService();
    final reward = RewardService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '🔒 Level ${index + 1}: ${lesson.localizedTitle}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pandaBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                loc.t('how_to_unlock'),
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // Opsi 1: Kerjakan kuis level sebelumnya
              if (index > 0) ...[
                ListTile(
                  tileColor: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.shade300, width: 1.5),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.quiz_rounded, color: Colors.white),
                  ),
                  title: Text(
                    loc.isEnglish ? 'Complete Level $index Quiz' : 'Selesaikan Kuis Level $index',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    loc.isEnglish
                        ? 'Earn stars ⭐ to unlock Level ${index + 1}'
                        : 'Dapatkan bintang ⭐ untuk membuka Level ${index + 1}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    Navigator.pop(ctx);
                    _onLessonTap(_lessons[index - 1], index - 1);
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Opsi 2: Buka langsung dengan 20 Bambu
              ListTile(
                tileColor: Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.green.shade300, width: 1.5),
                ),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryGreen,
                  child: Text('🎋', style: TextStyle(fontSize: 20)),
                ),
                title: Text(
                  loc.t('unlock_with_bamboo'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  loc.isEnglish
                      ? 'Current balance: ${reward.bamboo} Bamboo'
                      : 'Saldo kamu: ${reward.bamboo} Bambu',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.lock_open_rounded, color: AppColors.secondaryGreen),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (reward.bamboo >= 20) {
                    await reward.spendBamboo(20);
                    await reward.unlockLesson(lesson.id);
                    setState(() {
                      _syncLessons();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.secondaryGreen,
                        content: Text(loc.t('level_unlocked_success')),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.orange.shade800,
                        content: Text(loc.t('not_enough_bamboo')),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),

              // Opsi 3: Tonton Video Iklan (Buka Gratis Langsung)
              ListTile(
                tileColor: Colors.deepOrange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.deepOrange.shade300, width: 1.5),
                ),
                leading: const CircleAvatar(
                  backgroundColor: Colors.deepOrange,
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white),
                ),
                title: Text(
                  loc.t('unlock_with_ad'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  loc.isEnglish ? 'Unlock instantly for free' : 'Buka gratis instan tanpa menunggu',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.lock_open_rounded, color: Colors.deepOrange),
                onTap: () {
                  Navigator.pop(ctx);
                  AdMobService().showRewardedAd(
                    onUserEarnedReward: () async {
                      await reward.unlockLesson(lesson.id);
                      setState(() {
                        _syncLessons();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.secondaryGreen,
                          content: Text(loc.t('level_unlocked_success')),
                        ),
                      );
                    },
                    onAdUnavailable: (msg) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.orange.shade800,
                          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: loc.languageNotifier,
      builder: (context, _, __) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.gradeLevel.localizedTitle),
            actions: [
              // Bintang terkumpul badge
              Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalGradeStars',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const LanguageSwitchButton(compact: true),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.videocam_rounded, color: Colors.deepOrange),
                tooltip: loc.t('watch_ad_bonus'),
                onPressed: () {
                  AdMobService().showRewardedAd(
                    onUserEarnedReward: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.secondaryGreen,
                          content: Text(loc.t('level_bonus_stars')),
                        ),
                      );
                      setState(() {
                        _syncLessons();
                      });
                    },
                    onAdUnavailable: (msg) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.orange.shade800,
                          content: Text(
                            msg,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _lessons.length,
              itemBuilder: (context, index) {
                final lesson = _lessons[index];
                final isEven = index % 2 == 0;

                return Column(
                  children: [
                    // Zig-zag offset row
                    Align(
                      alignment: isEven ? Alignment.centerLeft : Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: isEven ? 20 : 0,
                          right: isEven ? 0 : 20,
                        ),
                        child: _buildLessonNode(lesson, index),
                      ),
                    ),
                    if (index < _lessons.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: List.generate(
                            3,
                            (i) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(vertical: 3),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLessonNode(LessonTopic lesson, int index) {
    final isLocked = !lesson.isUnlocked;
    final levelNumber = index + 1;

    return GestureDetector(
      onTap: () => _onLessonTap(lesson, index),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey[200] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocked ? Colors.grey[300]! : lesson.themeColor,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isLocked ? Colors.black12 : lesson.themeColor.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Level badge & emoji
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isLocked ? Colors.grey[300] : lesson.themeColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      isLocked ? '🔒' : lesson.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey : lesson.themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$levelNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              lesson.localizedTitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey : AppColors.pandaBlack,
              ),
            ),
            const SizedBox(height: 6),
            // Star rating display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (starIdx) {
                final isFilled = starIdx < lesson.starsEarned;
                return Icon(
                  isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFilled ? Colors.amber : Colors.grey[400],
                  size: 18,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
