import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.color,
    this.gradient,
    this.borderColor = AppColors.border,
    this.glowColor,
    this.blur = 24,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final Color borderColor;
  final Color? glowColor;
  final double blur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.surfaceHigh.withValues(alpha: 0.85),
                AppColors.surface.withValues(alpha: 0.9),
              ],
            ),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color:
                glowColor?.withValues(alpha: 0.2) ??
                Colors.black.withValues(alpha: 0.35),
            blurRadius: blur,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return box;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: box,
    );
  }
}
