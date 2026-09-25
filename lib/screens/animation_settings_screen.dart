import 'package:flutter/material.dart';

import '../services/animation_pref.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';

class AnimationSettingsScreen extends StatefulWidget {
  const AnimationSettingsScreen({super.key});

  @override
  State<AnimationSettingsScreen> createState() =>
      _AnimationSettingsScreenState();
}

class _AnimationSettingsScreenState extends State<AnimationSettingsScreen> {
  late bool _on = AnimationPref.instance.enabled.value;
  bool _busy = false;

  Future<void> _set(bool v) async {
    setState(() => _busy = true);
    await AnimationPref.instance.set(v);
    if (mounted) {
      setState(() {
        _on = v;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BackgroundDecor(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'ভিজ্যুয়াল',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.water_rounded,
                                  size: 19,
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'কার্ড অ্যানিমেশন',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'রক্তদাতা কার্ডে মাছের মতো সাঁতার/পানি-ঢেউ অ্যানিমেশন',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: _busy ? null : () => _set(!_on),
                                child: Container(
                                  width: 50,
                                  height: 28,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: _on
                                        ? AppColors.normal
                                        : AppColors.surfaceHigh,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: AnimatedAlign(
                                    duration: const Duration(milliseconds: 200),
                                    alignment: _on
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.info,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'অ্যানিমেশন বন্ধ করলে কার্ড দেখতে একদম শান্ত/ব্যাটারি-সেভ হবে — চাইলে আবার চালু করতে পারবেন।',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
