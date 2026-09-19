import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/admob_service.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';
import '../services/reward_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kid_button.dart';
import '../widgets/language_switch_button.dart';
import '../widgets/panda_avatar.dart';

class QuizScreen extends StatefulWidget {
  final LessonTopic lesson;
  final String? nextLessonId;

  const QuizScreen({
    Key? key,
    required this.lesson,
    this.nextLessonId,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizItem {
  final VocabItem target;
  final List<VocabItem> options;

  _QuizItem({required this.target, required this.options});
}

class _QuizScreenState extends State<QuizScreen> {
  int _questionIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;
  bool _answered = false;
  bool _isCorrect = false;

  late List<_QuizItem> _quizItems;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  void _generateQuestions() {
    final vocabs = List<VocabItem>.from(widget.lesson.vocabs)..shuffle();
    _quizItems = vocabs.map((vocab) {
      final others = widget.lesson.vocabs.where((v) => v.id != vocab.id).toList()..shuffle();
      final distractors = others.take(2).toList();
      final options = [vocab, ...distractors]..shuffle();
      return _QuizItem(target: vocab, options: options);
    }).toList();
  }

  void _chooseOption(int index) {
    if (_answered) return;

    final item = _quizItems[_questionIndex];
    final chosenVocab = item.options[index];
    final correct = chosenVocab.id == item.target.id;

    setState(() {
      _selectedOptionIndex = index;
      _answered = true;
      _isCorrect = correct;
      if (correct) {
        _score++;
        AudioService().playSuccess();
      }
    });
  }

  void _nextQuestion() {
    if (_questionIndex < _quizItems.length - 1) {
      setState(() {
        _questionIndex++;
        _answered = false;
        _selectedOptionIndex = null;
        _isCorrect = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final loc = LocalizationService();

    // Hitung bintang berdasarkan performa kuis
    int starsEarned = 1;
    if (_score == _quizItems.length) {
      starsEarned = 3;
    } else if (_score >= (_quizItems.length / 2)) {
      starsEarned = 2;
    }

    // Simpan progres ke RewardService secara permanen
    RewardService().saveLessonProgress(
      lessonId: widget.lesson.id,
      starsEarned: starsEarned,
      nextLessonId: widget.nextLessonId,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ValueListenableBuilder<AppLanguage>(
        valueListenable: loc.languageNotifier,
        builder: (context, lang, _) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PandaAvatar(
                  size: 100,
                  mood: PandaMood.excited,
                  speechText: loc.t('quiz_cheer'),
                ),
                const SizedBox(height: 16),
                Text(
                  loc.t('quiz_completed'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.pandaBlack,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.isEnglish
                      ? 'You answered $_score out of ${_quizItems.length} correctly!'
                      : 'Kamu menjawab $_score dari ${_quizItems.length} dengan benar!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                // Star row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isFilled = index < starsEarned;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isFilled ? Colors.amber : Colors.grey.shade400,
                        size: 38,
                      ),
                    );
                  }),
                ),

                if (widget.nextLessonId != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade300, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_open_rounded, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            loc.t('next_level_unlocked'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Rewarded Ad Button for bonus stars
                OutlinedButton.icon(
                  onPressed: () {
                    AdMobService().showRewardedAd(
                      onUserEarnedReward: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.secondaryGreen,
                            content: Text(loc.t('bonus_stars_claimed')),
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
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryYellow, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  icon: const Icon(Icons.play_circle_outline, color: Colors.deepOrange),
                  label: Text(
                    loc.t('quiz_bonus_stars_btn'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.pandaBlack),
                  ),
                ),

                const SizedBox(height: 16),
                KidButton(
                  text: loc.t('quiz_back_to_map'),
                  color: AppColors.secondaryGreen,
                  shadowColor: const Color(0xFF2E7D32),
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close quiz
                    Navigator.of(context).pop(); // Back to lesson map
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    final item = _quizItems[_questionIndex];
    final total = _quizItems.length;

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: loc.languageNotifier,
      builder: (context, lang, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(loc.t('quiz_title')),
            actions: const [
              LanguageSwitchButton(),
              SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress Bar
                  LinearProgressIndicator(
                    value: (_questionIndex + 1) / total,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.coralOrange),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 24),

                  // Question Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          loc.t('quiz_prompt'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.target.hanzi,
                          style: const TextStyle(
                            fontSize: 68,
                            fontWeight: FontWeight.bold,
                            color: AppColors.pandaBlack,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Options
                  Expanded(
                    child: ListView.builder(
                      itemCount: item.options.length,
                      itemBuilder: (context, index) {
                        final optionVocab = item.options[index];
                        final optionText = optionVocab.meaning;
                        Color btnColor = Colors.white;
                        Color textColor = AppColors.pandaBlack;
                        Color borderColor = Colors.black12;

                        if (_answered) {
                          if (optionVocab.id == item.target.id) {
                            btnColor = AppColors.secondaryGreen;
                            textColor = Colors.white;
                            borderColor = const Color(0xFF2E7D32);
                          } else if (index == _selectedOptionIndex) {
                            btnColor = Colors.redAccent;
                            textColor = Colors.white;
                            borderColor = Colors.red;
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: OutlinedButton(
                            onPressed: () => _chooseOption(index),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: btnColor,
                              side: BorderSide(color: borderColor, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Continue Button if answered
                  if (_answered) ...[
                    KidButton(
                      text: _questionIndex == total - 1 ? loc.t('quiz_see_results') : loc.t('quiz_next'),
                      color: _isCorrect ? AppColors.secondaryGreen : AppColors.coralOrange,
                      shadowColor: _isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFD84315),
                      onPressed: _nextQuestion,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
