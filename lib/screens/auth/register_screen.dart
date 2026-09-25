import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_decor.dart';
import '../../widgets/glass_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _bloodGroup = 'O+';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_name.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.length < 6) {
      _toast('সব ঘর পূরণ করুন (পাসওয়ার্ড কমপক্ষে ৬ অক্ষর)');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.instance.register(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        bloodGroup: _bloodGroup,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _toast(_messageOf(e.code));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _toast('কিছু একটা সমস্যা হয়েছে, আবার চেষ্টা করুন');
      }
    }
  }

  String _messageOf(String code) => switch (code) {
    'email-already-in-use' => 'এই ইমেইলে আগেই অ্যাকাউন্ট আছে',
    'invalid-email' => 'ইমেইল ঠিক নেই',
    'weak-password' => 'পাসওয়ার্ড খুব সহজ',
    _ => 'রেজিস্টার ব্যর্থ হয়েছে',
  };

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
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
                      'নতুন অ্যাকাউন্ট',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'পুরো নাম',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 21),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _phone,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'মোবাইল নম্বর',
                    prefixIcon: Icon(Icons.phone_outlined, size: 21),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _email,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'ইমেইল',
                    prefixIcon: Icon(Icons.mail_outline_rounded, size: 21),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'পাসওয়ার্ড (কমপক্ষে ৬ অক্ষর)',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 21),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ব্লাড গ্রুপ',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final g in _groups)
                      GestureDetector(
                        onTap: () => setState(() => _bloodGroup = g),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _bloodGroup == g
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _bloodGroup == g
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            g,
                            style: TextStyle(
                              color: _bloodGroup == g
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 26),
                GlassButton(
                  label: _busy ? 'তৈরি হচ্ছে...' : 'অ্যাকাউন্ট তৈরি করুন',
                  icon: _busy ? null : Icons.favorite_rounded,
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
