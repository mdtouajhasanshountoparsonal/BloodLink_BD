import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/request_service.dart';

class MessagingWrapper extends StatefulWidget {
  const MessagingWrapper({super.key, required this.child});

  final Widget child;

  @override
  State<MessagingWrapper> createState() => _MessagingWrapperState();
}

class _MessagingWrapperState extends State<MessagingWrapper> {
  final Set<String> _seenIds = {};
  bool _firstEmission = true;
  bool _disposed = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.incoming.listen(_handlePush);

    // Free-plan fallback: Firestore থেকে নতুন রিকোয়েস্ট আসার সাথে সাথে
    // অ্যাপে (খোলা থাকা অবস্থায়) রিয়েল-টাইম alert দেখাই — push notification ছাড়াই।
    _sub = RequestService.instance.requestsStream().listen((list) {
      if (_disposed) return;
      if (_firstEmission) {
        _seenIds.addAll(list.map((r) => r.id));
        _firstEmission = false;
        return;
      }
      final newOnes = list.where((r) => _seenIds.add(r.id)).toList();
      if (newOnes.isNotEmpty) {
        final r = newOnes.first;
        _showSnack(
          '🚨 নতুন রক্তের রিকোয়েস্ট',
          '${r.bloodGroup} ${r.urgency.label} — ${r.patientName} (${r.hospital})',
        );
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }

  void _handlePush(RemoteMessage m) {
    final notif = m.notification;
    if (notif == null || _disposed) return;
    _showSnack(notif.title ?? 'BloodLink', notif.body ?? '');
  }

  void _showSnack(String title, String body) {
    if (_disposed || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E2935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (body.isNotEmpty)
                Text(body, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}