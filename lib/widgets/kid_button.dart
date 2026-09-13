import 'package:flutter/material.dart';

class KidButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color shadowColor;
  final IconData? icon;
  final String? emoji;
  final double height;
  final double fontSize;

  const KidButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFF4CAF50),
    this.shadowColor = const Color(0xFF2E7D32),
    this.icon,
    this.emoji,
    this.height = 56,
    this.fontSize = 18,
  }) : super(key: key);

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: widget.height,
        margin: EdgeInsets.only(
          top: _isPressed ? 6 : 0,
          bottom: _isPressed ? 0 : 6,
        ),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: widget.shadowColor,
                    offset: const Offset(0, 6),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.emoji != null) ...[
                Text(
                  widget.emoji!,
                  style: TextStyle(fontSize: widget.fontSize + 4),
                ),
                const SizedBox(width: 8),
              ],
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: widget.fontSize + 4),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
