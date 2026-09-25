import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'usage_counter.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  Stream<AppUser?> get userStream =>
      _auth.authStateChanges().asyncMap((user) async {
        if (user == null) return null;
        final snap = await _db.collection('users').doc(user.uid).get();
        if (!snap.exists) return null;
        final data = Map<String, dynamic>.from(snap.data()!);
        data['uid'] = user.uid;
        return AppUser.fromJson(data);
      });

  Future<AppUser?> currentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final snap = await _db.collection('users').doc(u.uid).get();
    if (!snap.exists) return null;
    final data = Map<String, dynamic>.from(snap.data()!);
    data['uid'] = u.uid;
    return AppUser.fromJson(data);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String bloodGroup,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await _db
        .collection('users')
        .doc(uid)
        .set(
          AppUser(
            uid: uid,
            email: email,
            name: name,
            bloodGroup: bloodGroup,
            phone: phone,
          ).toJson(),
        );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> setAvailable(bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'available': value});
    UsageCounter.instance.trackWrite('users');
  }

  Future<void> setShowPhone(bool value) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'showPhone': value});
    UsageCounter.instance.trackWrite('users');
  }

  Future<void> updateLocation({double? latitude, double? longitude}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || latitude == null || longitude == null) return;
    await _db.collection('users').doc(uid).set({
      'latitude': latitude,
      'longitude': longitude,
    }, SetOptions(merge: true));
    UsageCounter.instance.trackWrite('users');
  }

  Future<void> updateProfile({
    String? name,
    String? bloodGroup,
    String? phone,
    int? donations,
    bool? verified,
    DateTime? lastDonation,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'name': ?name,
      'bloodGroup': ?bloodGroup,
      'phone': ?phone,
      'donations': ?donations,
      'verified': ?verified,
      'lastDonation': ?lastDonation,
    });
    UsageCounter.instance.trackWrite('users');
  }

  Future<void> signOut() => _auth.signOut();
}
