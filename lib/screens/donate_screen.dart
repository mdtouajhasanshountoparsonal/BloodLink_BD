import 'dart:math';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/request_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_header.dart';
import 'donation_info_screen.dart';

class DonateScreen extends StatefulWidget {
  const DonateScreen({super.key});

  @override
  State<DonateScreen> createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  bool? _available;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    AuthService.instance.userStream.listen((u) {
      if (!mounted) return;
      setState(() {
        _user = u;
        if (u != null) _available = u.available;
      });
    });
  }

  void _setAvailable(bool v) {
    setState(() => _available = v);
    AuthService.instance.setAvailable(v);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BackgroundDecor(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ডোনেট করুন', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                const Text(
                  'আপনার রক্ত অন্যকে জীবন দেয়',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (user != null) _DonorCard(user: user),
                const SizedBox(height: 20),
                _AvailabilityCard(
                  available: _available ?? true,
                  onChanged: _setAvailable,
                ),
                const SizedBox(height: 22),
                const SectionHeader(title: 'রক্তদানের উপকারিতা'),
                const SizedBox(height: 12),
                _BenefitsCard(onTapInfo: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DonationInfoScreen()),
                  );
                }),
                const SizedBox(height: 22),
                const SectionHeader(title: 'ডোনেশন নিয়ম'),
                const SizedBox(height: 12),
                const _EligibilityCard(),
                const SizedBox(height: 22),
                const SectionHeader(title: 'ডোনেশন হিস্টরি'),
                const SizedBox(height: 12),
                _historySection(user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _historySection(AppUser? user) {
    if (user == null) {
      return const _EmptyHistory();
    }
    return StreamBuilder<List<DonationRecord>>(
      stream: RequestService.instance.donationsHistoryStream(user.uid),
      builder: (context, snap) {
        final list = snap.data ?? const <DonationRecord>[];
        if (list.isEmpty) return const _EmptyHistory();
        return Column(
          children: [
            for (final rec in list.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HistoryItem(
                  date: '${rec.date.day}/${rec.date.month}/${rec.date.year}',
                  hospital: rec.hospital,
                  group: rec.bloodGroup,
                  patient: rec.patientName,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(18),
      child: const Row(
        children: [
          Icon(Icons.history, color: AppColors.textSecondary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'এখনো কোনো রেকর্ড নেই। রক্ত দিলে হাসপাতাল থেকে কনফার্ম করা হলে এখানে হিস্টরি দেখা যাবে।',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  const _DonorCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5470), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(Icons.water_drop, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BLOODLINK BD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    Text(
                      'Donor Card',
                      style: TextStyle(color: Colors.white70, fontSize: 11.5, letterSpacing: 0.4),
                    ),
                  ],
                ),
              ),
              if (user.verified)
                const Icon(Icons.verified_rounded, color: Colors.white, size: 22)
              else
                Icon(Icons.verified_rounded, color: Colors.white.withValues(alpha: 0.25), size: 22),
            ],
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'গ্রুপ ${user.bloodGroup} • উপলব্ধ: ${user.available ? 'হ্যাঁ' : 'না'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${user.donations} বার ডোনেশন',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 104,
                height: 104,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomPaint(painter: _QrPainter(20)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.available, required this.onChanged});

  final bool available;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = available ? AppColors.normal : AppColors.critical;

    return GlassCard(
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: activeColor.withValues(alpha: 0.6), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  available ? 'আপনি ডোনেট করতে প্রস্তুত' : 'ডোনেট করতে পারবেন না',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                const Text(
                  'এই স্ট্যাটাস সেভ হলে কাছের ডোনাররা দেখতে পাবে',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 56,
            height: 30,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(999),
            ),
            child: GestureDetector(
              onTap: () => onChanged(!available),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: available ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: activeColor.withValues(alpha: 0.5), blurRadius: 8)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.onTapInfo});

  final VoidCallback onTapInfo;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        children: [
          const _RuleRow(icon: Icons.favorite_outline, text: 'রক্তদানে ৩ জনের জীবন বাঁচে'),
          const _RuleRow(icon: Icons.insights_rounded, text: 'নতুন রক্তকণিকা তৈরি হয় — শরীর চাঙ্গা'),
          const _RuleRow(icon: Icons.heart_broken_outlined, text: 'হৃদরোগের ঝুঁকি কমায় (বিজ্ঞানসম্মত)'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTapInfo,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 17, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'বিস্তারিত জানুন',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: const Column(
        children: [
          _RuleRow(icon: Icons.monitor_weight_outlined, text: 'ওজন ৪৫ কেজির বেশি'),
          _RuleRow(icon: Icons.health_and_safety_outlined, text: 'শেষ ৩ মাসে ডোনেশন নেই'),
          _RuleRow(icon: Icons.science_outlined, text: 'হিমোগ্লোবিন ১২.৫ g/dL এর বেশি'),
          _RuleRow(icon: Icons.schedule, text: 'শেষ ৬ মাসে ট্যাটু/মেজর সার্জারি নেই'),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.normal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.normal),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.date,
    required this.hospital,
    required this.group,
    this.patient = '',
  });

  final String date;
  final String hospital;
  final String group;
  final String patient;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  hospital.isEmpty ? patient : patient.isEmpty ? hospital : '$patient • $hospital',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.normal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(color: AppColors.normal, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  group,
                  style: const TextStyle(color: AppColors.normal, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter(this.count);

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(7);
    final cell = size.width / count;
    final paint = Paint()..color = const Color(0xFF111111);

    for (var r = 0; r < count; r++) {
      for (var c = 0; c < count; c++) {
        if (rnd.nextDouble() > 0.52) {
          canvas.drawRect(
            Rect.fromLTWH(c * cell, r * cell, cell * 0.92, cell * 0.92),
            paint,
          );
        }
      }
    }

    void finder(double x, double y) {
      paint.color = const Color(0xFF111111);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, cell * 7, cell * 7), Radius.circular(cell)),
        paint,
      );
      paint.color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + cell, y + cell, cell * 5, cell * 5),
          Radius.circular(cell * 0.6),
        ),
        paint,
      );
      paint.color = const Color(0xFF111111);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + cell * 2, y + cell * 2, cell * 3, cell * 3),
          Radius.circular(cell * 0.4),
        ),
        paint,
      );
    }

    finder(0, 0);
    finder(size.width - cell * 7, 0);
    finder(0, size.height - cell * 7);
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => false;
}