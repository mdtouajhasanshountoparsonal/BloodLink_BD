import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  AppUser? _user;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await AuthService.instance.currentUser();
    if (mounted) setState(() => _user = u);
  }

  Future<void> _toggleShowPhone(bool v) async {
    setState(() => _saving = true);
    await AuthService.instance.setShowPhone(v);
    if (mounted) setState(() => _saving = false);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final showPhone = _user?.showPhone ?? true;
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
                    Text('প্রাইভেসি ও নিরাপত্তা',
                        style: Theme.of(context).textTheme.headlineMedium),
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
                        child: Row(
                          children: [
                            const Icon(Icons.phone_in_talk, color: AppColors.primary, size: 22),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ডোনারদের কাছে নম্বর দেখান',
                                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'বন্ধ করলে রোগী/ডোনাররা আপনার নম্বর দেখতে পারবে না, শুধু ইন-অ্যাপ চ্যাট করতে পারবে।',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _Switch(
                              value: showPhone,
                              onChanged: _saving ? null : _toggleShowPhone,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('যা আসলে শেয়ার হয়',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('নাম ও রক্তের গ্রুপ', 'ডোনার লিস্ট ও রিকোয়েস্টে দেখানো হয়।'),
                            _infoRow('অবস্থান (এলাকা)', 'কাছের ডোনার খুঁজতে দূরত্ব হিসাব করা হয়।'),
                            _infoRow('ডোনেশন সংখ্যা ও ভেরিফিকেশন', 'প্রোফাইলে সবাই দেখতে পায়।'),
                            _infoRow('নম্বর', 'শুধু ভেরিফাইড ডোনার/রোগী দেখে — উপরের স্যুইচ দিয়ে নিয়ন্ত্রণ করুন।'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('নিরাপত্তা টিপস',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('ফোনে ওটিপি/পিন কাউকে জানাবেন না', 'সরকারি প্রতিষ্ঠান কখনো ফোনে পিন চায় না।'),
                            _infoRow('ভুয়া নম্বর ভেরিফাই করতে বললে সতর্ক থাকুন', 'সন্দেহজনক হলে ইন-অ্যাপ রিপোর্ট করুন।'),
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

  Widget _infoRow(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Container(
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.normal : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
          ),
        ),
      ),
    );
  }
}