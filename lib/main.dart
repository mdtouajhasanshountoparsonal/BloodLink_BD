import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth/auth_gate.dart';
import 'services/animation_pref.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_meta_gate.dart';
import 'widgets/messaging_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  NotificationService.instance.init();
  AnimationPref.instance.load();
  runApp(const BloodLinkApp());
}

class BloodLinkApp extends StatelessWidget {
  const BloodLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodLink BD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MessagingWrapper(child: AppMetaGate(child: AuthGate())),
    );
  }
}
