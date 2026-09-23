import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_meta_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _open = 0;

  Future<void> _openUrl(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('লিংক খোলা যায়নি')));
    }
  }

  static const _faqs = [
    (
      'কিভাবে রক্তের রিকোয়েস্ট করব?',
      'হোম স্ক্রিনের "নতুন রিকোয়েস্ট" বাটনে চাপুন, রোগীর তথ্য, রক্তের গ্রুপ, হাসপাতাল ও প্রয়োজনীয় ব্যাগ সংখ্যা দিন। রিকোয়েস্ট ৬–২৪ ঘণ্টা (জরুরিভিত্তিতে) সক্রিয় থাকে।',
    ),
    (
      'কে রক্ত দিতে পারবেন?',
      '১৮–৬০ বছর বয়স, ওজন ৪৫ কেজি+, হিমোগ্লোবিন ১২.৫ g/dL+ এবং শেষ রক্তদানের ৩ মাস পার হলে রক্ত দিতে পারবেন।',
    ),
    (
      'রিকোয়েস্ট কীভাবে বন্ধ হয়?',
      'যথেষ্ট ব্যাগ রিজার্ভড হলে অথবা মেয়াদ শেষে রিকোয়েস্ট নিজে নিজে বন্ধ হয়ে যায়। রিকোয়েস্ট মালিক "রক্ত সম্পন্ন" চাপলেও বন্ধ হয়।',
    ),
    (
      'ডোনেশন রেকর্ড কীভাবে যোগ হয়?',
      'রোগী (রিকোয়েস্ট মালিক) আপনাকে "কনফার্ম" করলে আপনার প্রোফাইলে ১টি ডোনেশন, ভেরিফিকেশন ব্যাজ ও হিস্টরি যোগ হয়।',
    ),
    (
      'নম্বর কেন দেখা যায় না?',
      'ডোনাররা প্রাইভেসি সেটিংসে নম্বর লুকিয়ে রাখতে পারেন। চ্যাট ব্যবহার করে যোগাযোগ করুন।',
    ),
    (
      'অ্যাপটি কি বিনামূল্যে?',
      'হ্যাঁ, BloodLink BD বর্তমানে ফ্রি প্ল্যানে চলছে — সব ফিচার বিনামূল্যে।',
    ),
  ];

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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text('সাহায্য ও সাপোর্ট', style: Theme.of(context).textTheme.headlineMedium),
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
                        padding: const EdgeInsets.all(14),
                        child: const Row(
                          children: [
                            Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'কোনো সমস্যা হলে রিলিজ নোট চেক করুন। ব্যক্তিগত সহায়তার জন্য অ্যাপের "রিপোর্ট করুন" সেকশন অথবা ইমেইল support@bloodlinkbd.com',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('অফিসিয়াল ওয়েবসাইট ও ডেভেলপার',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      GlassCard(
                        radius: 18,
                        onTap: () => _openUrl(AppMetaService.defaultDownloadUrl),
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          children: [
                            Icon(Icons.public_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('নতুন ভার্সন / ডাউনলোড',
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                  SizedBox(height: 2),
                                  Text(
                                    'অফিসিয়াল BloodLink BD ওয়েবসাইট থেকে APK ডাউনলোড করুন',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCard(
                        radius: 18,
                        onTap: () => _openUrl(AppMetaService.portfolioUrl),
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          children: [
                            Icon(Icons.rocket_launch_rounded, color: AppColors.violet, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ডেভেলপার',
                                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                  SizedBox(height: 2),
                                  Text(
                                    'মোঃ তৌআজ্হাসান শাওন — পোর্টফোলিও দেখুন',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder(
                        future: AuthService.instance.currentUser(),
                        builder: (context, snap) {
                          final uid = snap.data?.uid ?? '';
                          return GlassCard(
                            radius: 18,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('আমার অ্যাপ আইডি (UID)',
                                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        uid.isEmpty ? 'লগ ইন করুন' : uid,
                                        maxLines: 2,
                                        style: TextStyle(
                                          color: AppColors.info,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                    if (uid.isNotEmpty)
                                      GestureDetector(
                                        onTap: () async {
                                          await Clipboard.setData(ClipboardData(text: uid));
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                            ..hideCurrentSnackBar()
                                            ..showSnackBar(const SnackBar(content: Text('UID কপি হয়েছে')));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.info.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
                                          ),
                                          child: const Text('কপি',
                                              style: TextStyle(color: AppColors.info, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'এই UID-টি Firebase Console → appMeta → main → admins অ্যারেতে বসালে আপনি অ্যাডমিন হবেন।',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text('সাধারণ প্রশ্ন (FAQ)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      for (var i = 0; i < _faqs.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FaqTile(
                            index: i,
                            open: _open == i,
                            question: _faqs[i].$1,
                            answer: _faqs[i].$2,
                            onTap: () => setState(() => _open = _open == i ? -1 : i),
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.index,
    required this.open,
    required this.question,
    required this.answer,
    required this.onTap,
  });

  final int index;
  final bool open;
  final String question;
  final String answer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text('${index + 1}.', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(question, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: open ? 0.5 : 0,
                    child: const Icon(Icons.expand_more, color: AppColors.textSecondary, size: 20),
                  ),
                ],
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text(
                  answer,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}