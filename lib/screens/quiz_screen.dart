import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/admob_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kid_button.dart';
import '../widgets/panda_avatar.dart';

class QuizScreen extends StatefulWidget {
  final LessonTopic lesson;

  const QuizScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _questionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _answered = false;
  bool _isCorrect = false;

  late List<QuizQuestion> _questions;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  void _generateQuestions() {
    final vocabs = widget.lesson.vocabs;
    _questions = vocabs.map((vocab) {
      // Pick other random options
      final others = vocabs.where((v) => v.id != vocab.id).map((v) => v.meaningId).toList();
      others.shuffle();
      final distractors = others.take(2).toList();
      final options = [vocab.meaningId, ...distractors]..shuffle();

      return QuizQuestion(
        prompt: 'Apa arti dari karakter ini?',
        hanziTarget: vocab.hanzi,
        correctAnswer: vocab.meaningId,
        options: options,
        emoji: vocab.emoji,
      );
    }).toList();
  }

  void _chooseOption(String option) {
    if (_answered) return;

    final q = _questions[_questionIndex];
    final correct = option == q.correctAnswer;

    setState(() {
      _selectedAnswer = option;
      _answered = true;
      _isCorrect = correct;
      if (correct) {
        _score++;
        AudioService().playSuccess();
      }
    });
  }

  void _nextQuestion() {
    if (_questionIndex < _questions.length - 1) {
      setState(() {
        _questionIndex++;
        _answered = false;
        _selectedAnswer = null;
        _isCorrect = false;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PandaAvatar(
              size: 100,
              mood: PandaMood.excited,
              speechText: 'Hore! Kamu hebat sekali! 🌟',
            ),
            const SizedBox(height: 16),
            const Text(
              'Latihan Selesai!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.pandaBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kamu menjawab $_score dari ${_questions.length} dengan benar!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 14),
            // Star row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Rewarded Ad Button for bonus stars
            OutlinedButton.icon(
              onPressed: () {
                AdMobService().showRewardedAd(
                  onUserEarnedReward: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.secondaryGreen,
                        content: Text('🎁 +2 Bintang Tambahan Berhasil Diklaim!'),
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
              label: const Text(
                'Tonton Video (Bintang +2) 🎁',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pandaBlack),
              ),
            ),

            const SizedBox(height: 16),
            KidButton(
              text: 'Kembali ke Peta 🗺️',
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_questionIndex];
    final total = _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis NiHao Kids 🎯'),
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
                      q.prompt,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      q.hanziTarget ?? '',
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
                  itemCount: q.options.length,
                  itemBuilder: (context, index) {
                    final option = q.options[index];
                    Color btnColor = Colors.white;
                    Color textColor = AppColors.pandaBlack;
                    Color borderColor = Colors.black12;

                    if (_answered) {
                      if (option == q.correctAnswer) {
                        btnColor = AppColors.secondaryGreen;
                        textColor = Colors.white;
                        borderColor = const Color(0xFF2E7D32);
                      } else if (option == _selectedAnswer) {
                        btnColor = Colors.redAccent;
                        textColor = Colors.white;
                        borderColor = Colors.red;
                      }
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: OutlinedButton(
                        onPressed: () => _chooseOption(option),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: btnColor,
                          side: BorderSide(color: borderColor, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          option,
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
                  text: _questionIndex == total - 1 ? 'Lihat Hasil! 🏆' : 'Lanjut ➡️',
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
  }
}
