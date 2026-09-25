import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final _incoming = StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get incoming => _incoming.stream;

  Future<void> init() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen(_incoming.add);
    FirebaseMessaging.onMessageOpenedApp.listen(_incoming.add);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _messaging.onTokenRefresh.listen(_saveToken);

    AuthService.instance.userStream.listen((user) async {
      if (user == null) return;
      await _saveToken(await _messaging.getToken());
      if (user.bloodGroup.isNotEmpty) {
        try {
          await _messaging.subscribeToTopic('blood_${user.bloodGroup}');
        } catch (_) {}
      }
    });
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    final uid = AuthService.instance.user?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
