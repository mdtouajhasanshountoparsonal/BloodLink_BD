import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// অ্যাপের রিমোট নিয়ন্ত্রণ (ফ্রি প্ল্যান-বান্ধব):
/// - প্রশাসক চাইলে অ্যাপ চিরতরে বন্ধ (force close) করতে পারেন
/// - নতুন ভার্সন এলে ইউজারকে নোটিফিকেশন + ডাউনলোড ওয়েবসাইট
class AppMeta {
  const AppMeta({
    this.forceClose = false,
    this.forceMessage = 'অ্যাপটি বন্ধ করা হয়েছে। পরে আবার চেষ্টা করুন।',
    this.latestVersion = '0.1.0',
    this.notice = 'নতুন ভার্সন পাওয়া গেছে',
    this.downloadUrl = '',
  });

  final bool forceClose;
  final String forceMessage;
  final String latestVersion;
  final String notice;
  final String downloadUrl;

  bool get hasUpdate =>
      _isNewer(latestVersion, AppMetaService.currentVersion);

  static bool _isNewer(String a, String b) {
    final pa = _parts(a);
    final pb = _parts(b);
    for (var i = 0; i < 3; i++) {
      if (pa[i] > pb[i]) return true;
      if (pa[i] < pb[i]) return false;
    }
    return false;
  }

  static List<int> _parts(String v) {
    final list = v.split(RegExp(r'[^0-9]+')).where((s) => s.isNotEmpty).toList();
    final out = <int>[];
    for (final s in list.take(3)) {
      out.add(int.tryParse(s) ?? 0);
    }
    while (out.length < 3) {
      out.add(0);
    }
    return out;
  }
}

class AppMetaService {
  AppMetaService._();
  static final AppMetaService instance = AppMetaService._();

  static const String currentVersion = '0.1.1';
  static const String defaultDownloadUrl =
      'https://github.com/mdtouajhasanshountoparsonal/BloodLink_BD/releases/download/v0.1.1/BloodLink_v0.1.1.apk';
  static const String portfolioUrl =
      'https://mdtouajhasanshountoparsonal.github.io/PORTFOLIO/';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<AppMeta> metaStream() {
    return _db.collection('appMeta').doc('main').snapshots().map((snap) {
      final data = snap.data() ?? <String, dynamic>{};
      final meta = AppMeta(
        forceClose: (data['forceClose'] ?? false) as bool,
        forceMessage: (data['forceMessage'] ?? 'অ্যাপটি বন্ধ করা হয়েছে। পরে আবার চেষ্টা করুন।') as String,
        latestVersion: (data['latestVersion'] ?? currentVersion) as String,
        notice: (data['notice'] ?? 'নতুন ভার্সন পাওয়া গেছে') as String,
        downloadUrl: (data['downloadUrl'] ?? defaultDownloadUrl) as String,
      );
      return meta;
    });
  }
}