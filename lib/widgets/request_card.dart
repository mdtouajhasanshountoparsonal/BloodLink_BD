import 'package:flutter/material.dart';

import '../models/blood_request.dart';
import '../theme/app_colors.dart';
import 'blood_group_chip.dart';
import 'glass_card.dart';
import 'urgency_chip.dart';

class RequestCard extends StatelessWidget {
  const RequestCard({super.key, required this.request, this.onTap});

  final BloodRequest request;
  final VoidCallback? onTap;

  String get _distance =>
      request.distanceKm >= 10 ? request.distanceKm.toStringAsFixed(0) : request.distanceKm.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      glowColor: request.urgency.color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BloodGroupChip(group: request.bloodGroup),
              const Spacer(),
              UrgencyChip(urgency: request.urgency),
            ],
          ),
          const SizedBox(height: 14),
          Text(request.patientName, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.local_hospital_outlined, text: request.hospital),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.place_outlined,
            text: request.distanceKm > 0 ? '${request.area} • $_distance km' : request.area,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.schedule,
            text: '${request.bags} bag • ${_timeOf(request.neededBy)}',
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          if (request.requesterName.isNotEmpty) ...[
            _InfoRow(
              icon: Icons.person_outline,
              text: 'রিকোয়েস্টকর্তা: ${request.requesterName}',
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(Icons.people_outline, size: 17, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${request.responseCount} জন সাড়া দিয়েছেন',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ),
              Text(
                'বিস্তারিত',
                style: TextStyle(
                  color: request.urgency.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.arrow_forward, size: 16, color: request.urgency.color),
            ],
          ),
        ],
      ),
    );
  }

  String _timeOf(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
      ],
    );
  }
}