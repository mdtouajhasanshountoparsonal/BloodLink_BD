import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _newRequest = true;
  bool _myRequestActivity = true;
  bool _donationReminder = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _newRequest = prefs.getBool('notif_new_request') ?? true;
      _myRequestActivity = prefs.getBool('notif_my_request') ?? true;
      _donationReminder = prefs.getBool('notif_reminder') ?? false;
    });
  }

  Future<void> _set(String key, bool v) async {
    setState(() => _busy = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, v);
    if (mounted) setState(() => _busy = false);
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text('নোটিফিকেশন', style: Theme.of(context).textTheme.headlineMedium),
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
                        child: Column(
                          children: [
                            _toggleRow(
                              icon: Icons.notifications_active_outlined,
                              title: 'নতুন রক্তের রিকোয়েস্ট',
                              body: 'আপনার গ্রুপের জন্য নতুন রিকোয়েস্ট এলে অ্যাপ-এর ভেতরে অ্যালার্ট দেখাবে',
                              value: _newRequest,
                              onChanged: (v) {
                                setState(() => _newRequest = v);
                                _set('notif_new_request', v);
                              },
                            ),
                            const Divider(height: 1, indent: 48, color: AppColors.border),
                            _toggleRow(
                              icon: Icons.swap_calls_outlined,
                              title: 'আমার রিকোয়েস্টের কার্যকলাপ',
                              body: 'কেউ সাড়া দিলে বা চ্যাট করলে জানিয়ে দেবে',
                              value: _myRequestActivity,
                              onChanged: (v) {
                                setState(() => _myRequestActivity = v);
                                _set('notif_my_request', v);
                              },
                            ),
                            const Divider(height: 1, indent: 48, color: AppColors.border),
                            _toggleRow(
                              icon: Icons.event_available_outlined,
                              title: 'ডোনেশন রিমাইন্ডার',
                              body: '৯০ দিন পর পুনরায় রক্ত দেওয়ার স্মরণীয়',
                              value: _donationReminder,
                              onChanged: (v) {
                                setState(() => _donationReminder = v);
                                _set('notif_reminder', v);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, size: 18, color: AppColors.info),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'এই মূহূর্তে অ্যাপটি ফ্রি প্ল্যানে আছে, তাই পুশ নোটিফিকেশন বন্ধ — অ্যালার্ট অ্যাপ-এর ভেতরে (Snackbar) দেখানো হয়।',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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

  Widget _toggleRow({
    required IconData icon,
    required String title,
    required String body,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _busy ? null : () => onChanged(!value),
            child: Container(
              width: 50,
              height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: value ? AppColors.normal : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
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