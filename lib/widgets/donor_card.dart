import 'package:flutter/material.dart';

import '../models/donor.dart';
import '../theme/app_colors.dart';
import 'blood_group_chip.dart';
import 'glass_card.dart';

class DonorCard extends StatelessWidget {
  const DonorCard({
    super.key,
    required this.donor,
    this.onCall,
    this.onChat,
    this.onWhatsApp,
    this.onTap,
    this.score,
  });

  final Donor donor;
  final VoidCallback? onCall;
  final VoidCallback? onChat;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onTap;
  final int? score;

  @override
  Widget build(BuildContext context) {
    final groupColor = BloodGroupChip.colorOf(donor.bloodGroup);
    final phoneHidden = !donor.showPhone || donor.phone.isEmpty;

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: onTap ?? onCall,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [groupColor.withValues(alpha: 0.9), groupColor.withValues(alpha: 0.45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              donor.bloodGroup,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        donor.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (donor.verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: AppColors.info, size: 17),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.near_me, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${donor.distanceKm.toStringAsFixed(1)} km • ${donor.donations} বার ডোনেশন',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                _StatusDot(status: donor.status),
                if (score != null) ...[
                  const SizedBox(height: 6),
                  _ScorePill(score: score!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _RoundAction(
                icon: phoneHidden ? Icons.phone_disabled : Icons.phone_in_talk,
                color: phoneHidden ? AppColors.textSecondary : AppColors.normal,
                onTap: phoneHidden ? null : onCall,
              ),
              const SizedBox(height: 8),
              if (onWhatsApp != null)
                _RoundAction(icon: Icons.chat_rounded, color: AppColors.normal, onTap: onWhatsApp)
              else
                _RoundAction(icon: Icons.chat_bubble_outline, color: AppColors.info, onTap: onChat),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 85
        ? AppColors.normal
        : score >= 70
            ? AppColors.info
            : score >= 55
                ? AppColors.urgent
                : AppColors.critical;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                '$score% ম্যাচ',
                style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final DonorStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: status.color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: status.color.withValues(alpha: 0.6), blurRadius: 5)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          status.label,
          style: TextStyle(color: status.color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }
}