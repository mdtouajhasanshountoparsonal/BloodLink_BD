import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.gradient,
    this.textColor = Colors.white,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color textColor;
  final bool expand;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final defaultGradient = LinearGradient(
      colors: [AppColors.primarySoft, AppColors.primaryDeep],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: gradient ?? defaultGradient,
          boxShadow: [
            BoxShadow(
              color:
                  (gradient == null ? AppColors.primary : AppColors.primarySoft)
                      .withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
