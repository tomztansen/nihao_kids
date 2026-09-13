import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PandaMood { happy, excited, thinking, cheering }

class PandaAvatar extends StatelessWidget {
  final double size;
  final PandaMood mood;
  final String? speechText;

  const PandaAvatar({
    Key? key,
    this.size = 100,
    this.mood = PandaMood.happy,
    this.speechText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (speechText != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              speechText!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.pandaBlack,
              ),
            ),
          ),
        ],
        // Cute Panda Drawing using Flutter Custom Widgets
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.pandaBlack, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ears
              Positioned(
                top: 2,
                left: 10,
                child: Container(
                  width: size * 0.28,
                  height: size * 0.28,
                  decoration: const BoxDecoration(
                    color: AppColors.pandaBlack,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 10,
                child: Container(
                  width: size * 0.28,
                  height: size * 0.28,
                  decoration: const BoxDecoration(
                    color: AppColors.pandaBlack,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Face Center
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: size * 0.15),
                    // Eye patches
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildEyePatch(size),
                        SizedBox(width: size * 0.15),
                        _buildEyePatch(size),
                      ],
                    ),
                    SizedBox(height: size * 0.05),
                    // Cute Nose
                    Container(
                      width: size * 0.14,
                      height: size * 0.08,
                      decoration: BoxDecoration(
                        color: AppColors.pandaBlack,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Smile
                    Text(
                      mood == PandaMood.excited ? '▽' : '‿',
                      style: TextStyle(
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pandaBlack,
                      ),
                    ),
                  ],
                ),
              ),
              // Cheeks Blush
              Positioned(
                bottom: size * 0.2,
                left: size * 0.15,
                child: Container(
                  width: size * 0.16,
                  height: size * 0.1,
                  decoration: BoxDecoration(
                    color: AppColors.sweetPink.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: size * 0.2,
                right: size * 0.15,
                child: Container(
                  width: size * 0.16,
                  height: size * 0.1,
                  decoration: BoxDecoration(
                    color: AppColors.sweetPink.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEyePatch(double size) {
    return Container(
      width: size * 0.24,
      height: size * 0.28,
      decoration: BoxDecoration(
        color: AppColors.pandaBlack,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Container(
          width: size * 0.08,
          height: size * 0.08,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
