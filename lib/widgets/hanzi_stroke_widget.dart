import 'package:flutter/material.dart';
import '../models/models.dart';
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

class _HanziStrokeWidgetState extends State<HanziStrokeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _progressAnimation;

  // Finger tracing strokes
  final List<List<Offset>> _userStrokes = [];
  bool _isTracingMode = false;
  double _animSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _progressAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOutCubic,
    );

    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant HanziStrokeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vocab.id != widget.vocab.id) {
      _userStrokes.clear();
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _replayAnimation() {
    _animController.reset();
    _animController.duration = Duration(milliseconds: (2400 / _animSpeed).round());
    _animController.forward();
  }

  void _clearCanvas() {
    setState(() {
      _userStrokes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    final isEn = loc.isEnglish;
    final char = widget.vocab.hanzi.isNotEmpty ? widget.vocab.hanzi[0] : '字';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode Selector Pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTabPill(
              icon: Icons.play_circle_fill_rounded,
              label: isEn ? 'Watch Strokes' : 'Urutan Goresan',
              isActive: !_isTracingMode,
              onTap: () => setState(() => _isTracingMode = false),
            ),
            const SizedBox(width: 8),
            _buildTabPill(
              icon: Icons.edit_rounded,
              label: isEn ? 'Finger Tracing' : 'Tulis Mandiri',
              isActive: _isTracingMode,
              onTap: () => setState(() => _isTracingMode = true),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Tianzige (米字格) Calligraphy Canvas
        Center(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9), // Lembaran kertas kaligrafi tradisional
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Grid Garis Panduan Tradisional (米字格)
                  const CustomPaint(
                    painter: TianzigePainter(),
                  ),

                  // 2. Tampilan Karakter
                  if (!_isTracingMode)
                    // Mode Animasi Goresan
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: StrokeRevealPainter(
                            char: char,
                            progress: _progressAnimation.value,
                          ),
                        );
                      },
                    )
                  else
                    // Mode Latihan Tulis Jari (Finger Tracing)
                    GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _userStrokes.add([details.localPosition]);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          if (_userStrokes.isNotEmpty) {
                            _userStrokes.last.add(details.localPosition);
                          }
                        });
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Bayangan tipis huruf sebagai panduan
                          Center(
                            child: Text(
                              char,
                              style: TextStyle(
                                fontSize: 130,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.withOpacity(0.20),
                                height: 1.0,
                              ),
                            ),
                          ),
                          // Goresan jari pengguna
                          CustomPaint(
                            painter: UserDrawingPainter(strokes: _userStrokes),
                          ),
                        ],
                      ),
                    ),
                ],
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
                onPressed: _replayAnimation,
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

              // Speed toggle (1x / 0.5x)
              ActionChip(
                backgroundColor: const Color(0xFFF5F5F5),
                label: Text(
                  _animSpeed == 1.0 ? '1.0x' : '0.5x (Lambat)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  setState(() {
                    _animSpeed = _animSpeed == 1.0 ? 0.5 : 1.0;
                    _replayAnimation();
                  });
                },
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clear Drawing
              OutlinedButton.icon(
                onPressed: _clearCanvas,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: Text(
                  loc.t('clear_canvas'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              const SizedBox(width: 10),
              if (_userStrokes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.secondaryGreen, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        isEn ? 'Good job!' : 'Bagus sekali!',
                        style: const TextStyle(
                          color: AppColors.secondaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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

/// Painter untuk Kotak Kaligrafi Tradisional Tianzige (米字格)
class TianzigePainter extends CustomPainter {
  const TianzigePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF9A9A).withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFFEF9A9A).withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final midX = size.width / 2;
    final midY = size.height / 2;

    // Garis putus-putus vertikal tengah
    _drawDashedLine(canvas, Offset(midX, 0), Offset(midX, size.height), dashPaint);

    // Garis putus-putus horizontal tengah
    _drawDashedLine(canvas, Offset(0, midY), Offset(size.width, midY), dashPaint);

    // Garis putus-putus diagonal kiri atas ke kanan bawah
    _drawDashedLine(canvas, const Offset(0, 0), Offset(size.width, size.height), dashPaint);

    // Garis putus-putus diagonal kanan atas ke kiri bawah
    _drawDashedLine(canvas, Offset(size.width, 0), Offset(0, size.height), dashPaint);

    // Garis tepi kotak dalam
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint..strokeWidth = 1.5,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 4.0;
    const double dashSpace = 4.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double count = (Offset(dx, dy).distance) / (dashWidth + dashSpace);

    for (int i = 0; i < count; i++) {
      final double startFraction = i / count;
      final double endFraction = (i * (dashWidth + dashSpace) + dashWidth) / Offset(dx, dy).distance;
      if (endFraction > 1.0) break;
      canvas.drawLine(
        Offset(p1.dx + dx * startFraction, p1.dy + dy * startFraction),
        Offset(p1.dx + dx * endFraction, p1.dy + dy * endFraction),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter untuk Animasi Sapuan Kuas Kaligrafi Hanzi
class StrokeRevealPainter extends CustomPainter {
  final String char;
  final double progress;

  const StrokeRevealPainter({
    required this.char,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Gambar huruf latar belakang (bayangan tipis abu-abu)
    final textPainterBase = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          fontSize: 130,
          fontWeight: FontWeight.bold,
          color: Colors.grey.withOpacity(0.18),
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      (size.width - textPainterBase.width) / 2,
      (size.height - textPainterBase.height) / 2,
    );
    textPainterBase.paint(canvas, textOffset);

    // 2. Gambar goresan kuas yang sedang menyapu (Clip path vertikal + horizontal dinamis)
    canvas.save();

    // Masking area progres penulisan kuas
    final clipHeight = size.height * progress.clamp(0.0, 1.0);
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, clipHeight));

    final textPainterActive = TextPainter(
      text: TextSpan(
        text: char,
        style: const TextStyle(
          fontSize: 130,
          fontWeight: FontWeight.bold,
          color: Color(0xFF263238), // Tinta kaligrafi pekat
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainterActive.paint(canvas, textOffset);

    // Indikator ujung kuas yang sedang menulis (bulatan tinta merah menyala)
    if (progress > 0.05 && progress < 0.95) {
      final brushIndicator = Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width * 0.5 + 20 * (1.0 - progress), clipHeight),
        4.5,
        brushIndicator,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StrokeRevealPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.char != char;
  }
}

/// Painter untuk merekam coretan jari anak pada kanvas
class UserDrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  const UserDrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD32F2F) // Tinta merah kaligrafi anak
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.length == 1) {
          canvas.drawCircle(stroke[0], 4.5, paint..style = PaintingStyle.fill);
          paint.style = PaintingStyle.stroke;
        }
        continue;
      }
      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant UserDrawingPainter oldDelegate) => true;
}
