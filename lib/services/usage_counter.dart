import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase free (Spark) plan-এর কোটা।
class SparkLimits {
  static const int readsPerDay = 50000;
  static const int writesPerDay = 20000;
  static const int storageGb = 1;
  static const int downloadGbPerMonth = 10;
}

/// এই ডিভাইস থেকে এই অ্যাপের নিজস্ব Firestore কার্যকলাপের আনুমানিক হিসাব।
///
/// দিনশেষে/ফায়ারবেজ কনসোলে আসল সংখ্যা আলাদা — এটা শুধু নিজের অ্যাপের
/// read/write অভ্যাস ট্র্যাক রাখে যাতে user ধারণা পায়।
class UsageCounter {
  UsageCounter._();
  static final UsageCounter instance = UsageCounter._();

  final Map<String, int> _reads = {};
  final Map<String, int> _writes = {};
  final Map<String, int> _writesByUid = {};
  bool _ready = false;
  Timer? _flush;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '(সাইন আউট)';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final reads = prefs.getString('usage_reads') ?? '';
    final writes = prefs.getString('usage_writes') ?? '';
    final byUid = prefs.getString('usage_writes_uid') ?? '';
    for (final part in reads.split('|')) {
      if (part.isEmpty) continue;
      final i = part.indexOf(':');
      if (i > 0) {
        _reads[part.substring(0, i)] = int.tryParse(part.substring(i + 1)) ?? 0;
      }
    }
    for (final part in writes.split('|')) {
      if (part.isEmpty) continue;
      final i = part.indexOf(':');
      if (i > 0) {
        _writes[part.substring(0, i)] =
            int.tryParse(part.substring(i + 1)) ?? 0;
      }
    }
    for (final part in byUid.split('|')) {
      if (part.isEmpty) continue;
      final i = part.indexOf(':');
      if (i > 0) {
        _writesByUid[part.substring(0, i)] =
            int.tryParse(part.substring(i + 1)) ?? 0;
      }
    }
    _ready = true;
  }

  String _key(String collection, String date) => '$collection@$date';

  void trackRead(String collection) => trackReadN(collection, 1);

  void trackReadN(String collection, int n) {
    if (!_ready || n <= 0) return;
    final k = _key(collection, _date(DateTime.now()));
    _reads[k] = (_reads[k] ?? 0) + n;
    _schedulePersist();
  }

  void trackWrite(String collection) => trackWriteN(collection, 1);

  void trackWriteN(String collection, int n) {
    if (!_ready || n <= 0) return;
    final now = DateTime.now();
    final k = _key(collection, _date(now));
    _writes[k] = (_writes[k] ?? 0) + n;
    final kk = _key(_uid, _date(now));
    _writesByUid[kk] = (_writesByUid[kk] ?? 0) + n;
    _schedulePersist();
  }

  void _schedulePersist() {
    _flush?.cancel();
    _flush = Timer(const Duration(seconds: 3), () => unawaited(_persist()));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usage_reads', _encode(_reads));
    await prefs.setString('usage_writes', _encode(_writes));
    await prefs.setString('usage_writes_uid', _encode(_writesByUid));
  }

  String _encode(Map<String, int> map) =>
      map.entries.map((e) => '${e.key}:${e.value}').join('|');

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int readsToday(String collection) {
    final k = _key(collection, _date(DateTime.now()));
    return _reads[k] ?? 0;
  }

  int writesToday(String collection) {
    final k = _key(collection, _date(DateTime.now()));
    return _writes[k] ?? 0;
  }

  int totalReadsToday() => _sumToday(_reads);
  int totalWritesToday() => _sumToday(_writes);

  int _sumToday(Map<String, int> map) {
    final today = _date(DateTime.now());
    return map.entries
        .where((e) => e.key.endsWith('@$today'))
        .fold(0, (a, e) => a + e.value);
  }

  /// শেষ ৭ দিনের (আজসহ) মোট read — ধারণা ও ছোট গ্রাফের জন্য।
  static const List<String> _weekdays = [
    'সোম',
    'মঙ্গল',
    'বুধ',
    'বৃহস্পতি',
    'শুক্র',
    'শনি',
    'রবি',
  ];

  List<(String, int)> lastSevenDaysReads() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: i));
      final date = _date(d);
      final total = _reads.entries
          .where((e) => e.key.endsWith('@$date'))
          .fold(0, (a, e) => a + e.value);
      return (i == 0 ? 'আজ' : '${d.day}/${d.month}', total);
    });
  }

  List<(String, int)> lastSevenDaysWrites() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: i));
      final date = _date(d);
      final total = _writes.entries
          .where((e) => e.key.endsWith('@$date'))
          .fold(0, (a, e) => a + e.value);
      return (i == 0 ? 'আজ' : '${d.day}/${d.month}', total);
    });
  }

  /// দিনভিত্তিক ব্যবহার (সবচেয়ে নতুন শেষে) — (লেবেল, রিড, রাইট)।
  List<({String label, int reads, int writes})> dailySummary({int days = 14}) {
    final now = DateTime.now();
    final out = <({String label, int reads, int writes})>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final date = _date(d);
      final r = _reads.entries
          .where((e) => e.key.endsWith('@$date'))
          .fold(0, (a, e) => a + e.value);
      final w = _writes.entries
          .where((e) => e.key.endsWith('@$date'))
          .fold(0, (a, e) => a + e.value);
      final label = i == 0
          ? 'আজ'
          : '${_weekdays[d.weekday - 1]} ${d.day}/${d.month}';
      out.add((label: label, reads: r, writes: w));
    }
    return out;
  }

  List<(String, int)> _seriesToday(Map<String, int> map) {
    final today = _date(DateTime.now());
    final agg = <String, int>{};
    map.forEach((k, v) {
      final i = k.indexOf('@');
      if (i < 0) return;
      if (!k.endsWith('@$today')) return;
      final c = k.substring(0, i);
      agg[c] = (agg[c] ?? 0) + v;
    });
    final list = agg.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return list;
  }

  List<(String, int)> readsTodayByCollection() => _seriesToday(_reads);
  List<(String, int)> writesTodayByCollection() => _seriesToday(_writes);

  /// আজকের write, অ্যাকাউন্ট (uid) অনুযায়ী — শুধু এই ডিভাইসে ঘটে যাওয়া।
  List<(String, int)> writesTodayByUid() {
    final today = _date(DateTime.now());
    final list = <(String, int)>[];
    _writesByUid.forEach((k, v) {
      if (!k.endsWith('@$today')) return;
      final i = k.indexOf('@');
      if (i > 0) list.add((k.substring(0, i), v));
    });
    list.sort((a, b) => b.$2.compareTo(a.$2));
    return list;
  }
}
