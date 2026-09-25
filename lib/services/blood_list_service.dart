import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/blood_list_entry.dart';
import 'usage_counter.dart';

/// রক্তদাতা তালিকা (roster) — সাধারণ ইউজার দেখে ও যোগাযোগ করে,
/// ম্যানেজার যোগ/সংশোধন/মুছে দেয়, অ্যাডমিন নম্বর ভেরিফাই করে।
class BloodListService {
  BloodListService._();
  static final BloodListService instance = BloodListService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int maxPhones = 5;

  CollectionReference<Map<String, dynamic>> get _coll =>
      _db.collection('bloodList');

  /// ভেরিফাইড আগে, তারপর নাম অনুযায়ী।
  Stream<List<BloodListEntry>> entriesStream() {
    return _coll
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => BloodListEntry.fromJson(d.id, d.data()))
              .toList();
          list.sort((a, b) {
            final av = a.verified ? 0 : 1;
            final bv = b.verified ? 0 : 1;
            if (av != bv) return av.compareTo(bv);
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          return list;
        })
        .handleError((Object _) => <BloodListEntry>[]);
  }

  Future<({bool ok, String message})> addEntry({
    required String name,
    required String bloodGroup,
    required List<String> phones,
    String email = '',
    String area = '',
    String note = '',
  }) async {
    try {
      await _coll.add(
        BloodListEntry(
          id: '',
          name: name.trim(),
          bloodGroup: bloodGroup,
          phones: phones
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList(),
          email: email.trim(),
          area: area.trim(),
          note: note.trim(),
          addedBy: '',
        ).toJson(),
      );
      UsageCounter.instance.trackWrite('bloodList');
      return (ok: true, message: 'তালিকায় যোগ হয়েছে');
    } catch (e) {
      return (ok: false, message: 'ব্যর্থ: $e');
    }
  }

  Future<({bool ok, String message})> deleteEntry(String id) async {
    try {
      await _coll.doc(id).delete();
      UsageCounter.instance.trackWrite('bloodList');
      return (ok: true, message: 'মুছে ফেলা হয়েছে');
    } catch (e) {
      return (ok: false, message: 'ব্যর্থ: $e');
    }
  }

  Future<({bool ok, String message})> setVerified(
    String id,
    bool verified,
  ) async {
    try {
      await _coll.doc(id).update({'verified': verified});
      UsageCounter.instance.trackWrite('bloodList');
      return (
        ok: true,
        message: verified ? 'নম্বর ভেরিফাইড' : 'ভেরিফিকেশন সরানো হয়েছে',
      );
    } catch (e) {
      return (ok: false, message: 'ব্যর্থ: $e');
    }
  }
}
