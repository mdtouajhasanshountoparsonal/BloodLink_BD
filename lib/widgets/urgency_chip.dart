import 'package:flutter/material.dart';

import '../models/blood_request.dart';

class UrgencyChip extends StatelessWidget {
  const UrgencyChip({super.key, required this.urgency});

  final Urgency urgency;

  @override
  Widget build(BuildContext context) {
    final color = urgency.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            urgency.label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}