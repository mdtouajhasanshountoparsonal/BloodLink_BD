import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/blood_request.dart';
import 'usage_counter.dart';

/// অ্যাডমিন প্যানেলের জন্য Firestore অপারেশন।
/// অ্যাডমিন চেনা যায় `appMeta/main.admins` অ্যারে থেকে (rules-এ enforced)।
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _meta =>
      _db.collection('appMeta').doc('main');

  /// নিয়মিত পড়তেই হবে না — গেটের metaStream ইতোমধ্যে অ্যাডমিন স্ট্যাটাস জানায় না।
  Future<bool> isAdmin(AppUser? user) async {
    if (user == null) return false;
    try {
      final snap = await _meta.get();
      final admins = (snap.data()?['admins'] as List<dynamic>?) ?? const [];
      return admins.any((a) => a == user.uid);
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchMeta() async {
    try {
      final snap = await _meta.get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  Future<({bool ok, String message})> saveAppMeta({
    bool? forceClose,
    String? forceMessage,
    String? latestVersion,
    String? downloadUrl,
    String? notice,
    List<String>? admins,
  }) async {
    try {
      final data = <String, dynamic>{
        'forceClose': ?forceClose,
        'forceMessage': ?forceMessage,
        'latestVersion': ?latestVersion,
        'downloadUrl': ?downloadUrl,
        'notice': ?notice,
        'admins': ?admins,
      };
      await _meta.set(data, SetOptions(merge: true));
      UsageCounter.instance.trackWrite('appMeta');
      return (ok: true, message: 'সংরক্ষিত হয়েছে');
    } catch (e) {
      return (ok: false, message: 'ব্যর্থ: $e');
    }
  }

  Stream<List<AppUser>> allUsersStream() {
    return _db.collection('users').snapshots().map((snap) {
      return snap.docs
          .map((d) => AppUser.fromJson(d.data()))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });
  }

  Stream<List<BloodRequest>> allRequestsStream() {
    return _db
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => BloodRequest.fromJson(d.data()))
          .toList()
        ..sort((a, b) {
          final aActive = a.status == 'active' ? 0 : 1;
          final bActive = b.status == 'active' ? 0 : 1;
          return aActive.compareTo(bActive);
        });
      return list;
    }).handleError((Object _) => <BloodRequest>[]);
  }

  Future<bool> closeRequest(String requestId) async {
    try {
      await _db.collection('requests').doc(requestId).update({
        'status': 'expired',
        'closedBy': 'admin',
        'closedAt': FieldValue.serverTimestamp(),
      });
      UsageCounter.instance.trackWrite('requests');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteRequest(String requestId) async {
    try {
      await _db.collection('requests').doc(requestId).delete();
      UsageCounter.instance.trackWrite('requests');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setUserBanned(String uid, bool banned) async {
    try {
      await _db.collection('users').doc(uid).update({'banned': banned});
      UsageCounter.instance.trackWrite('users');
      return true;
    } catch (_) {
      return false;
    }
  }
}
