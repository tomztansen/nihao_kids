import 'package:flutter/material.dart';
import '../data/curriculum_data.dart';
import '../models/models.dart';
import '../services/admob_service.dart';
import '../services/localization_service.dart';
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

  @override
  void initState() {
    super.initState();
    _lessons = widget.gradeLevel.grade == SchoolGrade.paud
        ? XingxingCurriculum.getPaudLessons()
        : widget.gradeLevel.grade == SchoolGrade.tk
            ? XingxingCurriculum.getTkLessons()
            : widget.gradeLevel.grade == SchoolGrade.sdLower
                ? MeiHuaLowerCurriculum.getLessons()
                : MeiHuaUpperCurriculum.getLessons();

    // Ensure first lesson is unlocked by default
    if (_lessons.isNotEmpty) {
      _lessons[0].isUnlocked = true;
    }
  }

  void _onLessonTap(LessonTopic lesson) {
    final loc = LocalizationService();
    if (!lesson.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.grey.shade800,
          content: Text(loc.t('level_locked')),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(lesson: lesson),
      ),
    ).then((_) {
      setState(() {});
    });
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
              const LanguageSwitchButton(compact: true),
              const SizedBox(width: 6),
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
                        child: _buildLessonNode(lesson, index + 1),
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

  Widget _buildLessonNode(LessonTopic lesson, int levelNumber) {
    final isLocked = !lesson.isUnlocked;

    return GestureDetector(
      onTap: () => _onLessonTap(lesson),
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
