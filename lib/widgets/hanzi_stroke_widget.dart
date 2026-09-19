import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/models.dart';
import '../services/hanzi_data_service.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class HanziStrokeWidget extends StatefulWidget {
  final VocabItem vocab;
  final VoidCallback? onPlaySound;

  const HanziStrokeWidget({
    Key? key,
    required this.vocab,
    this.onPlaySound,
  }) : super(key: key);

  @override
  State<HanziStrokeWidget> createState() => _HanziStrokeWidgetState();
}

class _HanziStrokeWidgetState extends State<HanziStrokeWidget> {
  WebViewController? _webViewController;
  bool _isWebViewReady = false;
  bool _isTracingMode = false;
  double _animSpeed = 0.5;
  bool _quizCompleted = false;

  late List<String> _characters;
  int _selectedCharIndex = 0;

  String get _currentChar => _characters.isNotEmpty ? _characters[_selectedCharIndex] : '字';

  @override
  void initState() {
    super.initState();
    _extractCharacters();
    _initWebViewController();
  }

  void _extractCharacters() {
    final hanzi = widget.vocab.hanzi;
    // Extract Hanzi characters
    final matches = RegExp(r'[\u4e00-\u9fa5]').allMatches(hanzi);
    _characters = matches.map((m) => m.group(0)!).toList();
    if (_characters.isEmpty && hanzi.isNotEmpty) {
      _characters = [hanzi[0]];
    }
    _selectedCharIndex = 0;
  }

  @override
  void didUpdateWidget(covariant HanziStrokeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vocab.id != widget.vocab.id) {
      setState(() {
        _extractCharacters();
        _quizCompleted = false;
        _isTracingMode = false;
      });
      _loadCharacterInWebView();
    }
  }

  void _initWebViewController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          if (msg.message == 'complete') {
            setState(() {
              _quizCompleted = true;
            });
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isWebViewReady = true;
              });
            }
          },
        ),
      );

    _webViewController = controller;
    _loadCharacterInWebView();
  }

  void _loadCharacterInWebView() {
    if (_webViewController == null) return;
    final char = _currentChar;
    final charDataJson = HanziDataService().getCharDataJson(char);
    final writerJs = HanziDataService().hanziWriterJs ?? '';

    final html = _buildHtmlContent(
      char: char,
      charDataJson: charDataJson,
      writerJs: writerJs,
      speed: _animSpeed,
      isQuizMode: _isTracingMode,
    );

    _webViewController!.loadHtmlString(html, baseUrl: 'https://localhost');
  }

  String _buildHtmlContent({
    required String char,
    required String charDataJson,
    required String writerJs,
    required double speed,
    required bool isQuizMode,
  }) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, maximum-scale=1.0">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
      -webkit-touch-callout: none;
      -webkit-user-select: none;
      user-select: none;
    }
    html, body {
      width: 100%;
      height: 100%;
      background: transparent;
      display: flex;
      justify-content: center;
      align-items: center;
      overflow: hidden;
    }
    .tianzige-box {
      position: relative;
      width: 220px;
      height: 220px;
      border: 3px solid #E57373;
      border-radius: 16px;
      background: #FFFDF9;
      box-shadow: 0 4px 12px rgba(229, 57, 53, 0.08);
      overflow: hidden;
    }
    .tianzige-grid {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
    }
    #hanzi-target {
      position: relative;
      width: 220px;
      height: 220px;
      z-index: 2;
    }
  </style>
  <script>
    $writerJs
  </script>
</head>
<body>
  <div class="tianzige-box">
    <!-- Red dashed calligraphy grid (米字格) -->
    <svg class="tianzige-grid" viewBox="0 0 220 220">
      <line x1="110" y1="0" x2="110" y2="220" stroke="#EF9A9A" stroke-width="1.2" stroke-dasharray="5,5" opacity="0.6"/>
      <line x1="0" y1="110" x2="220" y2="110" stroke="#EF9A9A" stroke-width="1.2" stroke-dasharray="5,5" opacity="0.6"/>
      <line x1="0" y1="0" x2="220" y2="220" stroke="#EF9A9A" stroke-width="1.0" stroke-dasharray="4,4" opacity="0.4"/>
      <line x1="0" y1="220" x2="220" y2="0" stroke="#EF9A9A" stroke-width="1.0" stroke-dasharray="4,4" opacity="0.4"/>
    </svg>
    <div id="hanzi-target"></div>
  </div>

  <script>
    var currentChar = '$char';
    var charData = $charDataJson;
    var writer = null;
    var isQuiz = ${isQuizMode ? 'true' : 'false'};
    var speed = $speed;

    function initWriter() {
      var target = document.getElementById('hanzi-target');
      if (!target) return;
      target.innerHTML = '';

      if (typeof HanziWriter === 'undefined') {
        target.innerHTML = '<div style="font-size:110px; line-height:220px; color:#D32F2F; text-align:center;">' + currentChar + '</div>';
        return;
      }

      writer = HanziWriter.create('hanzi-target', currentChar, {
        width: 220,
        height: 220,
        padding: 15,
        strokeAnimationSpeed: speed,
        delayBetweenStrokes: 220,
        strokeColor: '#D32F2F',
        radicalColor: '#1976D2',
        outlineColor: '#CFD8DC',
        drawingColor: '#2E7D32',
        drawingWidth: 20,
        showOutline: true,
        showCharacter: false,
        charDataLoader: function(char, onComplete) {
          if (charData) {
            onComplete(charData);
          } else {
            fetch('https://cdn.jsdelivr.net/npm/hanzi-writer-data@2.0/' + encodeURIComponent(char) + '.json')
              .then(function(r) { return r.json(); })
              .then(function(d) { onComplete(d); })
              .catch(function(e) { console.error(e); });
          }
        }
      });

      if (isQuiz) {
        startQuiz();
      } else {
        writer.animateCharacter();
      }
    }

    function replayStrokes() {
      if (writer) {
        writer.showOutline();
        writer.animateCharacter();
      }
    }

    function setSpeed(newSpeed) {
      speed = newSpeed;
      if (writer) {
        writer.update({ strokeAnimationSpeed: newSpeed });
        writer.animateCharacter();
      }
    }

    function startQuiz() {
      if (writer) {
        writer.quiz({
          onMistake: function(strokeData) {
            if (window.FlutterBridge) {
              window.FlutterBridge.postMessage('mistake');
            }
          },
          onCorrectStroke: function(strokeData) {
            if (window.FlutterBridge) {
              window.FlutterBridge.postMessage('correct');
            }
          },
          onComplete: function(summary) {
            if (window.FlutterBridge) {
              window.FlutterBridge.postMessage('complete');
            }
          }
        });
      }
    }

    window.onload = function() {
      initWriter();
    };
  </script>
</body>
</html>
''';
  }

  void _replayStrokes() {
    setState(() {
      _quizCompleted = false;
    });
    _webViewController?.runJavaScript('replayStrokes();');
  }

  void _toggleSpeed() {
    setState(() {
      _animSpeed = (_animSpeed == 0.5) ? 1.0 : 0.5;
    });
    _webViewController?.runJavaScript('setSpeed($_animSpeed);');
  }

  void _setMode(bool isTracing) {
    setState(() {
      _isTracingMode = isTracing;
      _quizCompleted = false;
    });
    _loadCharacterInWebView();
  }

  void _selectChar(int index) {
    if (_selectedCharIndex == index) return;
    setState(() {
      _selectedCharIndex = index;
      _quizCompleted = false;
    });
    _loadCharacterInWebView();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    final isEn = loc.isEnglish;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode Selector Tabs (Urutan Goresan / Tulis Mandiri)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabPill(
              icon: Icons.play_circle_fill_rounded,
              label: isEn ? 'Watch Strokes' : 'Urutan Goresan',
              isActive: !_isTracingMode,
              onTap: () => _setMode(false),
            ),
            const SizedBox(width: 8),
            _buildTabPill(
              icon: Icons.edit_rounded,
              label: isEn ? 'Practice Writing' : 'Tulis Mandiri',
              isActive: _isTracingMode,
              onTap: () => _setMode(true),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Multi-Character Selector (e.g. for "你好" -> "你", "好")
        if (_characters.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_characters.length, (idx) {
                final c = _characters[idx];
                final isSelected = idx == _selectedCharIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => _selectChar(idx),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE53935) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE53935),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : const Color(0xFFE53935),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

        // Tianzige (米字格) Container with HanziWriter inside WebView
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE57373), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: _webViewController != null
                  ? WebViewWidget(controller: _webViewController!)
                  : const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Controls bar under Tianzige
        if (!_isTracingMode)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Replay Button
              ElevatedButton.icon(
                onPressed: _replayStrokes,
                icon: const Icon(Icons.replay_rounded, size: 20),
                label: Text(
                  loc.t('replay_strokes'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.pandaBlack,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  elevation: 2,
                ),
              ),
              const SizedBox(width: 8),

              // Speed toggle (0.5x / 1.0x)
              ActionChip(
                backgroundColor: const Color(0xFFF5F5F5),
                label: Text(
                  _animSpeed == 0.5 ? '⚡ 0.5x (Lambat)' : '⚡ 1.0x (Cepat)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _toggleSpeed,
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset / Try again Quiz
              OutlinedButton.icon(
                onPressed: _loadCharacterInWebView,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  isEn ? 'Retry Quiz' : 'Ulangi Latihan',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100),
                  side: const BorderSide(color: Color(0xFFFFB74D), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 10),

              // Celebration badge if completed
              if (_quizCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.secondaryGreen, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎉 ', style: TextStyle(fontSize: 14)),
                      Text(
                        isEn ? 'Good job!' : 'Bagus sekali!',
                        style: const TextStyle(
                          color: AppColors.secondaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

        const SizedBox(height: 8),
        Text(
          !_isTracingMode
              ? (isEn
                  ? 'Follow the stroke order: top to bottom, left to right!'
                  : 'Perhatikan urutan goresan: dari atas ke bawah, kiri ke kanan!')
              : (isEn
                  ? 'Trace the character with your finger on the red grid!'
                  : 'Tulis aksara dengan jari tanganmu di atas kotak merah!'),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF78909C),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabPill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondaryGreen : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

