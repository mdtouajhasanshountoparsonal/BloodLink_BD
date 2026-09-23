import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/background_decor.dart';
import '../main_shell.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.userStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snap.data;
        if (snap.hasError || user == null) {
          return const LoginScreen();
        }
        if (user.banned) {
          return const _BannedScreen();
        }
        return const MainShell();
      },
    );
  }
}

class _BannedScreen extends StatelessWidget {
  const _BannedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BackgroundDecor(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.critical.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.critical, width: 2),
                    ),
                    child: const Icon(Icons.gpp_bad_rounded, color: AppColors.critical, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'অ্যাকাউন্ট ব্যান করা হয়েছে',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'আপনার অ্যাকাউন্টটি প্রশাসনের পক্ষ থেকে বন্ধ করা হয়েছে। '
                    'ভুল হলে অ্যাপের সাহায্য সেকশন থেকে যোগাযোগ করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    onPressed: () => AuthService.instance.signOut(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textSecondary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('লগ আউট'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}