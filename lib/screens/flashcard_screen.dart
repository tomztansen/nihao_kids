import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/audio_service.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';
import '../widgets/hanzi_stroke_widget.dart';
import '../widgets/kid_button.dart';
import '../widgets/language_switch_button.dart';
import 'quiz_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final LessonTopic lesson;

  const FlashcardScreen({Key? key, required this.lesson}) : super(key: key);

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentIndex = 0;
  bool _showStrokeTab = false;

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
    final loc = LocalizationService();
    AudioService().playHanziVoice(_currentVocab.id, _currentVocab.pinyin);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1500),
        backgroundColor: AppColors.secondaryGreen,
        content: Text('${loc.t('audio_playing')} ${_currentVocab.hanzi} (${_currentVocab.pinyin})'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: loc.languageNotifier,
      builder: (context, _, __) {
        final vocab = _currentVocab;
        final total = widget.lesson.vocabs.length;
        final toneColor = AppColors.getToneColor(vocab.tone);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.lesson.localizedTitle),
            actions: [
              const LanguageSwitchButton(compact: true),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: AppColors.pandaBlack, size: 28),
                tooltip: loc.t('listen_audio'),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                  const SizedBox(height: 10),

                  // Tab Switcher (Kartu Kata vs Urutan Goresan)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _showStrokeTab = false),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_showStrokeTab ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: !_showStrokeTab
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  loc.t('vocab_card'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: !_showStrokeTab ? widget.lesson.themeColor : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _showStrokeTab = true),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _showStrokeTab ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _showStrokeTab
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  loc.t('stroke_order'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _showStrokeTab ? widget.lesson.themeColor : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Main Content Card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_showStrokeTab) ...[
                              // TAB 1: KARTU KATA STANDAR
                              Text(
                                vocab.emoji,
                                style: const TextStyle(fontSize: 50),
                              ),
                              const SizedBox(height: 4),

                              // Hanzi (Tap to speak)
                              GestureDetector(
                                onTap: _playPronunciation,
                                child: Text(
                                  vocab.hanzi,
                                  style: const TextStyle(
                                    fontSize: 58,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.pandaBlack,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Pinyin with Tone Tag
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: toneColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Audio Button
                              ElevatedButton.icon(
                                onPressed: _playPronunciation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryYellow,
                                  foregroundColor: AppColors.pandaBlack,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: const BorderSide(color: Colors.amber, width: 2),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                icon: const Icon(Icons.volume_up_rounded, size: 24),
                                label: Text(
                                  loc.t('listen_audio'),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),

                              const SizedBox(height: 10),
                              const Divider(),
                              const SizedBox(height: 4),

                              // Meaning (ID or EN dynamically)
                              Text(
                                vocab.meaning,
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
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                                Text(
                                  '${vocab.exampleSentencePinyin ?? ""} (${vocab.exampleSentence ?? ""})',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                ),
                              ],
                            ] else ...[
                              // TAB 2: ANIMASI URUTAN GORESAN (TIANZIGE 米字格)
                              Text(
                                '${vocab.pinyin} • ${vocab.meaning}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: toneColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              HanziStrokeWidget(
                                key: ValueKey(vocab.id),
                                vocab: vocab,
                                onPlaySound: _playPronunciation,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

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
                                text: loc.t('quiz'),
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
                                text: loc.t('next'),
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
      },
    );
  }
}

