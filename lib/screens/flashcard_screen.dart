import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kid_button.dart';
import 'quiz_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final LessonTopic lesson;

  const FlashcardScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;

  VocabItem get _currentVocab => widget.lesson.vocabs[_currentIndex];

  @override
  void initState() {
    super.initState();
    // Otomatis bunyikan kata saat kartu pertama terbuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playPronunciation();
    });
  }

  void _nextCard() {
    if (_currentIndex < widget.lesson.vocabs.length - 1) {
      setState(() => _currentIndex++);
      _playPronunciation();
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _playPronunciation();
    }
  }

  void _playPronunciation() {
    AudioService().playHanziVoice(_currentVocab.id, _currentVocab.pinyin);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.secondaryGreen,
        content: Text('🔊 Memutar suara: ${_currentVocab.hanzi} (${_currentVocab.pinyin})'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocab = _currentVocab;
    final total = widget.lesson.vocabs.length;
    final toneColor = AppColors.getToneColor(vocab.tone);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.pandaBlack, size: 28),
            tooltip: 'Putar Suara',
            onPressed: _playPronunciation,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1}/$total',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pandaBlack,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentIndex + 1) / total,
                backgroundColor: Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(widget.lesson.themeColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 14),

              // Main Flashcard
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: widget.lesson.themeColor.withOpacity(0.3), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: widget.lesson.themeColor.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Emoji Icon
                      Text(
                        vocab.emoji,
                        style: const TextStyle(fontSize: 54),
                      ),
                      const SizedBox(height: 6),

                      // Hanzi (Tap to speak)
                      GestureDetector(
                        onTap: _playPronunciation,
                        child: Text(
                          vocab.hanzi,
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: AppColors.pandaBlack,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Pinyin with Tone Tag (Tap to speak)
                      GestureDetector(
                        onTap: _playPronunciation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: toneColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: toneColor, width: 2),
                          ),
                          child: Text(
                            vocab.pinyin,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: toneColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // BIG PROMINENT SOUND BUTTON
                      ElevatedButton.icon(
                        onPressed: _playPronunciation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryYellow,
                          foregroundColor: AppColors.pandaBlack,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(color: Colors.amber, width: 2),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        icon: const Icon(Icons.volume_up_rounded, size: 28),
                        label: const Text(
                          'DENGARKAN SUARA 🔊',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 4),

                      // Indonesian Translation
                      Text(
                        vocab.meaningId,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pandaBlack,
                        ),
                      ),

                      if (vocab.exampleSentenceHanzi != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          vocab.exampleSentenceHanzi!,
                          style: const TextStyle(fontSize: 14, color: Colors.black82),
                        ),
                        Text(
                          '${vocab.exampleSentencePinyin ?? ""} (${vocab.exampleSentenceId ?? ""})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Navigation & Quiz Button Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 26),
                    onPressed: _currentIndex > 0 ? _prevCard : null,
                    color: AppColors.pandaBlack,
                  ),
                  Expanded(
                    child: _currentIndex == total - 1
                        ? KidButton(
                            text: 'Mulai Kuis Seru! 🎯',
                            color: AppColors.coralOrange,
                            shadowColor: const Color(0xFFD84315),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizScreen(lesson: widget.lesson),
                                ),
                              );
                            },
                          )
                        : KidButton(
                            text: 'Berikutnya ➡️',
                            color: widget.lesson.themeColor,
                            shadowColor: widget.lesson.themeColor.withOpacity(0.7),
                            onPressed: _nextCard,
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 26),
                    onPressed: _currentIndex < total - 1 ? _nextCard : null,
                    color: AppColors.pandaBlack,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
