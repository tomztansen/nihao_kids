import 'dart:math';
import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

/// Modal Parental Gate untuk mematuhi regulasi Google Play Families Policy & COPPA.
/// Mengharuskan orang dewasa menjawab perhitungan matematika acak sebelum mengakses transaksi.
class ParentalGateDialog extends StatefulWidget {
  final VoidCallback onPassed;

  const ParentalGateDialog({Key? key, required this.onPassed}) : super(key: key);

  static Future<void> show(BuildContext context, {required VoidCallback onPassed}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ParentalGateDialog(onPassed: onPassed),
    );
  }

  @override
  State<ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<ParentalGateDialog> {
  late int _num1;
  late int _num2;
  late int _answer;
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateMathChallenge();
  }

  void _generateMathChallenge() {
    final rand = Random();
    _num1 = 15 + rand.nextInt(25); // 15..39
    _num2 = 12 + rand.nextInt(30); // 12..41
    _answer = _num1 + _num2;
  }

  void _verify() {
    final loc = LocalizationService();
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = loc.t('enter_answer_error'));
      return;
    }

    final parsed = int.tryParse(text);
    if (parsed == _answer) {
      Navigator.of(context).pop();
      widget.onPassed();
    } else {
      setState(() {
        _errorMessage = loc.t('math_error');
      });
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Text('👨‍👩‍👧', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              loc.t('parental_gate_title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.t('parental_gate_adult_desc'),
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300, width: 2),
              ),
              child: Text(
                '$_num1 + $_num2 = ?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: Color(0xFF37474F),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: loc.t('write_answer_hint'),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.secondaryGreen, width: 2),
                ),
              ),
              onSubmitted: (_) => _verify(),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.t('cancel'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: Text(loc.t('continue_btn'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
