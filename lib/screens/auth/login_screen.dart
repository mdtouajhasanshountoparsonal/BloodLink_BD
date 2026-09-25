import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_decor.dart';
import '../../widgets/glass_button.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _toast('ইমেইল আর পাসওয়ার্ড দিন');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.instance.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) setState(() => _busy = false);
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
    'invalid-email' => 'ইমেইল ঠিক নেই',
    'user-disabled' => 'অ্যাকাউন্টটি নিষ্ক্রিয়',
    'user-not-found' => 'এই ইমেইলে কোনো অ্যাকাউন্ট নেই',
    'wrong-password' => 'পাসওয়ার্ড ভুল',
    'invalid-credential' => 'ইমেইল বা পাসওয়ার্ড ভুল',
    _ => 'লগইন ব্যর্থ হয়েছে',
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 84,
                  height: 84,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primarySoft, AppColors.primaryDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const Text(
                  'স্বাগতম',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'BloodLink BD-তে লগইন করুন',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
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
                    hintText: 'পাসওয়ার্ড',
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 21),
                  ),
                ),
                const SizedBox(height: 26),
                GlassButton(
                  label: _busy ? 'লগইন হচ্ছে...' : 'লগইন',
                  icon: _busy ? null : Icons.login_rounded,
                  onTap: _submit,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'অ্যাকাউন্ট নেই?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text(
                        'রেজিস্টার করুন',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
