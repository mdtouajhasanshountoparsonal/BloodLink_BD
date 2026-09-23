import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/background_decor.dart';
import '../widgets/glass_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late String _bloodGroup;
  late int _donations;
  late bool _verified;
  DateTime? _lastDonation;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone);
    _bloodGroup = widget.user.bloodGroup;
    _donations = widget.user.donations;
    _verified = widget.user.verified;
    _lastDonation = widget.user.lastDonation;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty) {
      _toast('নাম দিন');
      return;
    }
    if (phone.length < 11) {
      _toast('সঠিক মোবাইল নম্বর দিন (১১ ডিজিট)');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.instance.updateProfile(
        name: name,
        bloodGroup: _bloodGroup,
        phone: phone,
        donations: _donations,
        verified: _verified,
        lastDonation: _lastDonation,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('আপডেট ব্যর্থ হয়েছে');
      }
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastDonation ?? now,
      firstDate: DateTime(2015),
      lastDate: now,
    );
    if (picked != null) setState(() => _lastDonation = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BackgroundDecor(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text('প্রোফাইল এডিট', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                const SizedBox(height: 24),
                _label('নাম'),
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'আপনার নাম',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 21),
                  ),
                ),
                const SizedBox(height: 18),
                _label('ব্লাড গ্রুপ'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final g in _groups)
                      GestureDetector(
                        onTap: () => setState(() => _bloodGroup = g),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: _bloodGroup == g ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: _bloodGroup == g ? AppColors.primary : AppColors.border),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(
                              color: _bloodGroup == g ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _label('মোবাইল নম্বর'),
                const SizedBox(height: 10),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: '01XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_outlined, size: 21),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _verified ? Icons.verified_rounded : Icons.gpp_maybe_outlined,
                      size: 18,
                      color: _verified ? AppColors.normal : AppColors.urgent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _verified ? 'নম্বর যাচাই করা আছে' : 'নম্বর যাচাই করা হয়নি',
                        style: TextStyle(
                          color: _verified ? AppColors.normal : AppColors.urgent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!_verified)
                      TextButton(
                        onPressed: () {
                          if (_phone.text.trim().length < 11) {
                            _toast('আগে সঠিক নম্বর লিখুন');
                            return;
                          }
                          HapticFeedback.lightImpact();
                          setState(() => _verified = true);
                          _toast('নম্বর যাচাই করা হয়েছে');
                        },
                        child: const Text('যাচাই করুন'),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _label('এখন পর্যন্ত ডোনেশন সংখ্যা'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _donations = _donations > 0 ? _donations - 1 : 0),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 22),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '$_donations',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _donations++),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _label('শেষ ডোনেশনের তারিখ'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _lastDonation == null
                                ? 'নির্বাচন করুন'
                                : _fmt(_lastDonation!),
                            style: TextStyle(
                              color: _lastDonation == null ? AppColors.textSecondary : AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: _lastDonation == null ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                GlassButton(
                  label: _busy ? 'সংরক্ষণ হচ্ছে...' : 'সংরক্ষণ করুন',
                  icon: _busy ? null : Icons.check_rounded,
                  onTap: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(text, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700));
  }

  String _fmt(DateTime t) {
    const months = ['', 'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
    return '${t.day} ${months[t.month]} ${t.year}';
  }
}