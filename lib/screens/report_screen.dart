import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/usage_counter.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_card.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const _kinds = [
    ('user', 'কোনো ব্যবহারকারী', Icons.person_outline),
    ('bug', 'টেকনিক্যাল সমস্যা', Icons.bug_report_outlined),
    ('other', 'অন্যান্য', Icons.miscellaneous_services_outlined),
  ];

  String _kind = 'user';
  final _detailsCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final uid = AuthService.instance.user?.uid;
    if (uid == null) return;
    final details = _detailsCtrl.text.trim();
    if (details.isEmpty) {
      _toast('বিস্তারিত লিখুন');
      return;
    }
    if (details.length > 1950) {
      _toast('টেক্সট অনেক বড় — ২০০০ অক্ষরের মধ্যে লিখুন');
      return;
    }
    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporter': uid,
        'kind': _kind,
        'details': details,
        'createdAt': FieldValue.serverTimestamp(),
      });
      UsageCounter.instance.trackWrite('reports');
      if (!mounted) return;
      _detailsCtrl.clear();
      _toast('রিপোর্ট পাঠানো হয়েছে — ধন্যবাদ!');
    } catch (_) {
      _toast('রিপোর্ট পাঠানো ব্যর্থ হয়েছে');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
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
                    Text('রিপোর্ট করুন', style: Theme.of(context).textTheme.headlineMedium),
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('কী রিপোর্ট করছেন?',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            const Text(
                              'ভুয়া অ্যাকাউন্ট, হয়রানি, ভুল তথ্য — সব রিপোর্ট গোপন থাকে।',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                for (final (k, label, icon) in _kinds)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () => setState(() => _kind = k),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: _kind == k
                                                ? AppColors.primary.withValues(alpha: 0.15)
                                                : AppColors.surface,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: _kind == k ? AppColors.primary : AppColors.border,
                                              width: _kind == k ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(icon,
                                                  size: 18,
                                                  color: _kind == k ? AppColors.primary : AppColors.textSecondary),
                                              const SizedBox(height: 5),
                                              Text(
                                                label,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: _kind == k ? AppColors.primary : AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: TextField(
                                controller: _detailsCtrl,
                                maxLines: 5,
                                maxLength: 2000,
                                decoration: const InputDecoration(
                                  hintText: 'বিস্তারিত লিখুন... (কী ঘটেছে? কোন অ্যাকাউন্ট?)',
                                  border: InputBorder.none,
                                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: _busy ? null : _submit,
                              child: Container(
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppColors.primarySoft, AppColors.primaryDeep],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  _busy ? 'পাঠানো হচ্ছে...' : 'রিপোর্ট পাঠান',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
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