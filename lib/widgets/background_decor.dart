import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BackgroundDecor extends StatelessWidget {
  const BackgroundDecor({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(top: -140, right: -110, child: _glow(AppColors.primary, 0.16, 340)),
        Positioned(top: 330, left: -150, child: _glow(AppColors.info, 0.09, 320)),
        Positioned(bottom: -120, right: -80, child: _glow(AppColors.violet, 0.08, 300)),
        child,
      ],
    );
  }

  Widget _glow(Color color, double opacity, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}