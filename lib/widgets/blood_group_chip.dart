import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BloodGroupChip extends StatelessWidget {
  const BloodGroupChip({super.key, required this.group, this.compact = false});

  final String group;
  final bool compact;

  static Color colorOf(String group) => switch (group) {
    'A+' || 'A-' => AppColors.info,
    'B+' || 'B-' => AppColors.normal,
    'AB+' || 'AB-' => AppColors.violet,
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(group);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 7 : 9,
            height: compact ? 7 : 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            group,
            style: TextStyle(
              color: color,
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
