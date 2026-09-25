import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum Urgency {
  critical('জরুরি', AppColors.critical),
  urgent('দ্রুত', AppColors.urgent),
  normal('সাধারণ', AppColors.normal);

  const Urgency(this.label, this.color);
  final String label;
  final Color color;
}

class BloodRequest {
  BloodRequest({
    required this.id,
    required this.patientName,
    required this.bloodGroup,
    required this.hospital,
    required this.area,
    required this.distanceKm,
    required this.bags,
    required this.urgency,
    required this.neededBy,
    DateTime? expiresAt,
    this.responseCount = 0,
    this.uid = '',
    this.status = 'active',
    this.rebroadcastCount = 0,
    this.confirmedDonor,
    this.requesterName = '',
    this.requesterPhone = '',
    this.latitude,
    this.longitude,
  }) : expiresAt = expiresAt ?? DateTime.now().add(lifetimeFor(urgency));

  final String id;
  final String uid;
  final String patientName;
  final String bloodGroup;
  final String hospital;
  final String area;
  final double distanceKm;
  final int bags;
  final Urgency urgency;
  final DateTime neededBy;
  final DateTime expiresAt;
  final int responseCount;
  final String status;
  final int rebroadcastCount;
  final String? confirmedDonor;
  final String requesterName;
  final String requesterPhone;
  final double? latitude;
  final double? longitude;

  bool get isExpired => status == 'expired';

  bool get isFulfilled => status == 'fulfilled';

  bool get isActive => status == 'active';

  bool get isClosed => isExpired || isFulfilled;

  bool expiredByTime(DateTime now) =>
      status != 'expired' && expiresAt.isBefore(now);

  bool get isMine => uid.isNotEmpty;

  static Duration lifetimeFor(Urgency urgency) => switch (urgency) {
    Urgency.critical => const Duration(hours: 6),
    Urgency.urgent => const Duration(hours: 12),
    Urgency.normal => const Duration(hours: 24),
  };

  int get lifetimeHours => BloodRequest.lifetimeFor(urgency).inHours;

  String remainingLabel() {
    final left = expiresAt.difference(DateTime.now());
    if (left.isNegative) return 'বন্ধ';
    final h = left.inHours;
    final m = left.inMinutes.remainder(60);
    if (h > 0) return '$h ঘণ্টা $m মি';
    return '$m মিনিট';
  }

  factory BloodRequest.fromJson(Map<String, dynamic> json) {
    final urgency = switch (json['urgency'] as String?) {
      'critical' => Urgency.critical,
      'urgent' => Urgency.urgent,
      _ => Urgency.normal,
    };
    return BloodRequest(
      id: (json['id'] ?? json['requestId']) as String,
      uid: (json['uid'] ?? '') as String,
      patientName: (json['patientName'] ?? '') as String,
      bloodGroup: (json['bloodGroup'] ?? 'O+') as String,
      hospital: (json['hospital'] ?? '') as String,
      area: (json['area'] ?? '') as String,
      distanceKm: ((json['distanceKm'] ?? 0) as num).toDouble(),
      bags: (json['bags'] ?? 1) as int,
      urgency: urgency,
      neededBy: (json['neededBy'] as Timestamp).toDate(),
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate(),
      responseCount: (json['responseCount'] ?? 0) as int,
      status: (json['status'] ?? 'active') as String,
      rebroadcastCount: (json['rebroadcastCount'] ?? 0) as int,
      confirmedDonor: (json['confirmedDonor'] as String?),
      requesterName: (json['requesterName'] ?? '') as String,
      requesterPhone: (json['requesterPhone'] ?? '') as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'uid': uid,
    'patientName': patientName,
    'bloodGroup': bloodGroup,
    'hospital': hospital,
    'area': area,
    'distanceKm': distanceKm,
    'bags': bags,
    'urgency': urgency.name,
    'neededBy': neededBy,
    'expiresAt': expiresAt,
    'responseCount': responseCount,
    'status': status,
    'rebroadcastCount': rebroadcastCount,
    'confirmedDonor': confirmedDonor,
    'requesterName': requesterName,
    'requesterPhone': requesterPhone,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
