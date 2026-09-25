import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/blood_request.dart';
import '../models/donor.dart';
import 'usage_counter.dart';

class RequestResponse {
  const RequestResponse({
    required this.uid,
    required this.name,
    required this.bloodGroup,
    required this.status,
    this.phone = '',
  });

  final String uid;
  final String name;
  final String bloodGroup;
  final String status;
  final String phone;

  bool get isDonors => status == 'donate' || status == 'maybe';
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.from,
    required this.fromName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String from;
  final String fromName;
  final String text;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] ?? '') as String,
    from: (json['from'] ?? '') as String,
    fromName: (json['fromName'] ?? '') as String,
    text: (json['text'] ?? '') as String,
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
  );
}

class DonationRecord {
  const DonationRecord({
    required this.id,
    required this.hospital,
    required this.patientName,
    required this.bloodGroup,
    required this.date,
  });

  final String id;
  final String hospital;
  final String patientName;
  final String bloodGroup;
  final DateTime date;

  factory DonationRecord.fromJson(Map<String, dynamic> json) => DonationRecord(
    id: (json['id'] ?? '') as String,
    hospital: (json['hospital'] ?? '') as String,
    patientName: (json['patientName'] ?? '') as String,
    bloodGroup: (json['bloodGroup'] ?? '') as String,
    date:
        (json['date'] as Timestamp?)?.toDate() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// একই Firestore stream একাধিক screen/subscriber-এর মধ্যে share করে,
/// যেন free plan-এর read quota শেষ না হয়ে যায়।
///
/// গুরুত্বপূর্ণ: প্রতিটি subscriber-এর আলাদা broadcast controller থাকে,
/// ভেতরের একমাত্র stream subscription সব controller-কে forward করে,
/// আর নতুন subscriber আসলে সর্বশেষ value আবার seed করে।
class _Shared<T> {
  _Shared(this._factory);

  final Stream<T> Function() _factory;
  StreamSubscription? _inner;
  final Set<StreamController<T>> _peers = {};
  T? _lastValue;

  Stream<T> get stream {
    late final StreamController<T> controller;
    controller = StreamController<T>.broadcast(
      onListen: () {
        _peers.add(controller);
        final last = _lastValue;
        if (last != null) {
          controller.add(last);
        }
        _inner ??= _factory().listen(
          (value) {
            _lastValue = value;
            for (final peer in List.of(_peers)) {
              if (!peer.isClosed) peer.add(value);
            }
          },
          onError: (Object e, StackTrace st) {
            for (final peer in List.of(_peers)) {
              if (!peer.isClosed) peer.addError(e, st);
            }
          },
        );
      },
      onCancel: () {
        _peers.remove(controller);
        if (_peers.isEmpty) {
          _inner?.cancel();
          _inner = null;
        }
      },
    );
    return controller.stream;
  }
}

class RequestService {
  RequestService._() {
    unawaited(UsageCounter.instance.init());
    _requestsShared = _Shared(
      () => _requestsQuery().snapshots().map(_mapRequests),
    );
    _donorsShared = _Shared(() => _donorsQuery().snapshots().map(_mapDonors));
  }
  static final RequestService instance = RequestService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final _Shared<List<BloodRequest>> _requestsShared;
  late final _Shared<List<Donor>> _donorsShared;

  List<BloodRequest> _mapRequests(QuerySnapshot<Map<String, dynamic>> snap) {
    UsageCounter.instance.trackReadN('requests', snap.docs.length);
    var list = snap.docs.map((d) {
      final json = Map<String, dynamic>.from(d.data());
      json['id'] = d.id;
      return BloodRequest.fromJson(json);
    }).toList();

    // শুধু সক্রিয় + সময়সীমার ভেতরে থাকা রিকোয়েস্টই দেখাই।
    final now = DateTime.now();
    list = list.where((r) {
      if (r.status != 'active') return false;
      if (!r.expiredByTime(now)) return true;
      unawaited(expireIfOverdue(r));
      return false;
    }).toList();
    return list;
  }

  Query<Map<String, dynamic>> _requestsQuery() => _db
      .collection('requests')
      .orderBy('createdAt', descending: true)
      .limit(100);

  List<Donor> _mapDonors(QuerySnapshot<Map<String, dynamic>> snap) {
    UsageCounter.instance.trackReadN('users', snap.docs.length);
    return snap.docs.map((d) {
      final json = d.data();
      final available = (json['available'] ?? true) as bool;
      return Donor.fromJson(
        Map<String, dynamic>.from(json),
        uid: d.id,
        available: available,
      );
    }).toList();
  }

  Query<Map<String, dynamic>> _donorsQuery() =>
      _db.collection('users').where('isDonor', isEqualTo: true).limit(200);

  CollectionReference<Map<String, dynamic>> _responses(String requestId) =>
      _db.collection('requests').doc(requestId).collection('responses');

  Stream<List<RequestResponse>> responsesStream(String requestId) {
    return _responses(requestId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) {
          UsageCounter.instance.trackReadN('responses', snap.docs.length);
          return snap.docs.map((d) {
            final j = d.data();
            return RequestResponse(
              uid: d.id,
              name: (j['name'] ?? '') as String,
              bloodGroup: (j['bloodGroup'] ?? 'O+') as String,
              status: (j['status'] ?? 'maybe') as String,
              phone: (j['phone'] ?? '') as String,
            );
          }).toList();
        });
  }

  Future<void> respond({
    required String requestId,
    required String uid,
    required String name,
    required String bloodGroup,
    required String status,
    String phone = '',
  }) async {
    final ref = _responses(requestId).doc(uid);
    final existing = await ref.get();
    UsageCounter.instance.trackRead('responses');
    await ref.set({
      'uid': uid,
      'name': name,
      'bloodGroup': bloodGroup,
      'status': status,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
    UsageCounter.instance.trackWrite('responses');
    if (!existing.exists) {
      await _db.collection('requests').doc(requestId).update({
        'responseCount': FieldValue.increment(1),
      });
      UsageCounter.instance.trackWrite('requests');
    }
  }

  CollectionReference<Map<String, dynamic>> _chat(String requestId) =>
      _db.collection('requests').doc(requestId).collection('chat');

  Stream<List<ChatMessage>> chatStream(String requestId) {
    return _chat(requestId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
          UsageCounter.instance.trackReadN('chat', snap.docs.length);
          return snap.docs.map((d) {
            final j = Map<String, dynamic>.from(d.data());
            j['id'] = d.id;
            return ChatMessage.fromJson(j);
          }).toList();
        });
  }

  Future<void> sendChatMessage({
    required String requestId,
    required String from,
    required String fromName,
    required String text,
  }) async {
    await _chat(requestId).add({
      'from': from,
      'fromName': fromName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    UsageCounter.instance.trackWrite('chat');
  }

  Stream<BloodRequest> requestStream(String id) {
    return _db.collection('requests').doc(id).snapshots().map((doc) {
      UsageCounter.instance.trackRead('requests');
      final json = Map<String, dynamic>.from(doc.data() ?? {});
      json['id'] = doc.id;
      return BloodRequest.fromJson(json);
    });
  }

  Future<void> expireIfOverdue(BloodRequest r) async {
    if (r.isExpired || !r.expiredByTime(DateTime.now())) return;
    try {
      await _db.collection('requests').doc(r.id).update({
        'status': 'expired',
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': 'auto',
      });
      UsageCounter.instance.trackWrite('requests');
    } catch (_) {
      // Rules / connection issues — keep local filtering working.
    }
  }

  Future<void> rebroadcast(String requestId, Duration lifetime) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'active',
      'expiresAt': DateTime.now().add(lifetime),
      'rebroadcastCount': FieldValue.increment(1),
      'closedAt': FieldValue.delete(),
      'closedBy': FieldValue.delete(),
    });
    UsageCounter.instance.trackWrite('requests');
  }

  // ব্যাগের চাহিদা পূরণ হলে / রক্ত পাওয়া গেলে রিকোয়েস্ট বন্ধ করা হয়
  Future<void> fulfill(String requestId, {String? confirmedDonor}) async {
    try {
      await _db.collection('requests').doc(requestId).update({
        'status': 'fulfilled',
        'closedAt': FieldValue.serverTimestamp(),
        'closedBy': 'fulfill',
        'confirmedDonor': ?confirmedDonor,
      });
      UsageCounter.instance.trackWrite('requests');
    } catch (_) {
      // ignore — পরের snapshot-এ আবার চেষ্টা হবে
    }
  }

  // মালিক নিজেই 'রক্ত সম্পন্ন' করে রিকোয়েস্ট বন্ধ করে
  Future<void> closeRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': 'fulfilled',
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': 'fulfill',
    });
    UsageCounter.instance.trackWrite('requests');
  }

  Stream<List<BloodRequest>> requestsStream({Urgency? urgency, String? query}) {
    if (urgency == null && (query == null || query.trim().isEmpty)) {
      return _requestsShared.stream;
    }
    return _requestsShared.stream.map((list) {
      var result = list;
      if (urgency != null) {
        result = result.where((r) => r.urgency == urgency).toList();
      }
      if (query != null && query.trim().isNotEmpty) {
        final ql = query.trim().toLowerCase();
        result = result.where((r) {
          return r.bloodGroup.toLowerCase().contains(ql) ||
              r.area.toLowerCase().contains(ql) ||
              r.hospital.toLowerCase().contains(ql) ||
              r.patientName.toLowerCase().contains(ql);
        }).toList();
      }
      return result;
    });
  }

  Stream<List<Donor>> donorsStream({String? bloodGroup}) {
    if (bloodGroup == null) return _donorsShared.stream;
    return _donorsShared.stream.map(
      (list) => list.where((d) => d.bloodGroup == bloodGroup).toList(),
    );
  }

  Future<void> addRequest(BloodRequest request) async {
    final ref = request.id.isEmpty
        ? _db.collection('requests').doc()
        : _db.collection('requests').doc(request.id);
    final data = request.toFirestore();
    data['id'] = ref.id;
    await ref.set(data);
    UsageCounter.instance.trackWrite('requests');
  }

  /// অন্য ব্যবহারকারীর public প্রোফাইল (লাইভ)
  Stream<Donor?> userStreamByUid(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((d) {
      UsageCounter.instance.trackRead('users');
      if (!d.exists) return null;
      final json = Map<String, dynamic>.from(d.data()!);
      return Donor.fromJson(
        json,
        uid: d.id,
        available: (json['available'] ?? true) as bool,
      );
    });
  }

  Future<Donor?> userByUid(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    UsageCounter.instance.trackRead('users');
    if (!d.exists) return null;
    final json = Map<String, dynamic>.from(d.data()!);
    return Donor.fromJson(
      json,
      uid: d.id,
      available: (json['available'] ?? true) as bool,
    );
  }

  /// রোগী (রিকোয়েস্ট মালিক) ডোনারকে কনফার্ম করলে:
  /// ডোনারের donations++, lastDonation=আজ, verified=true + ইতিহাসে যোগ + রিকোয়েস্ট বন্ধ
  Future<void> confirmDonation({
    required String requestId,
    required String donorUid,
    required String donorGroup,
    required String patientName,
    required String hospital,
  }) async {
    final req = await _db.collection('requests').doc(requestId).get();
    final reqUid = (req.data()?['uid'] ?? '') as String;
    final batch = _db.batch();
    final donorRef = _db.collection('users').doc(donorUid);
    batch.update(donorRef, {
      'donations': FieldValue.increment(1),
      'lastDonation': FieldValue.serverTimestamp(),
      'verified': true,
      'lastDonationByRequest': requestId,
    });
    batch.set(donorRef.collection('donationsHistory').doc(), {
      'requestId': requestId,
      'requestUid': reqUid,
      'donorUid': donorUid,
      'patientName': patientName,
      'hospital': hospital,
      'bloodGroup': donorGroup,
      'date': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('requests').doc(requestId), {
      'status': 'fulfilled',
      'closedAt': FieldValue.serverTimestamp(),
      'closedBy': 'fulfill',
      'confirmedDonor': donorUid,
    });
    await batch.commit();
    UsageCounter.instance.trackWriteN('users', 2);
    UsageCounter.instance.trackWrite('requests');
  }

  /// নিজের ডোনেশন হিস্টরি (লাইভ)
  Stream<List<DonationRecord>> donationsHistoryStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('donationsHistory')
        .orderBy('date', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) {
          UsageCounter.instance.trackReadN(
            'donationsHistory',
            snap.docs.length,
          );
          return snap.docs.map((d) {
            final j = Map<String, dynamic>.from(d.data());
            j['id'] = d.id;
            return DonationRecord.fromJson(j);
          }).toList();
        });
  }
}
