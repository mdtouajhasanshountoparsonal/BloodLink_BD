import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum DonorStatus {
  available('উপলব্ধ', AppColors.normal),
  busy('ব্যস্ত', AppColors.urgent),
  unavailable('অনুপলব্ধ', AppColors.critical);

  const DonorStatus(this.label, this.color);
  final String label;
  final Color color;
}

class Donor {
  const Donor({
    this.uid = '',
    required this.name,
    required this.bloodGroup,
    this.distanceKm = 0,
    this.status = DonorStatus.available,
    this.donations = 0,
    this.monthsSinceLast = 0,
    this.responseRate = 0,
    this.verified = false,
    this.latitude,
    this.longitude,
    this.phone = '',
    this.lastDonation,
    this.showPhone = true,
  });

  final String uid;
  final String name;
  final String bloodGroup;
  final double distanceKm;
  final DonorStatus status;
  final int donations;
  final int monthsSinceLast;
  final double responseRate;
  final bool verified;
  final double? latitude;
  final double? longitude;
  final String phone;
  final DateTime? lastDonation;
  final bool showPhone;

  factory Donor.fromJson(
    Map<String, dynamic> json, {
    required String uid,
    required bool available,
  }) {
    return Donor(
      uid: uid,
      name: (json['name'] ?? '') as String,
      bloodGroup: (json['bloodGroup'] ?? 'O+') as String,
      distanceKm: ((json['distanceKm'] ?? 0) as num).toDouble(),
      status: available ? DonorStatus.available : DonorStatus.unavailable,
      donations: (json['donations'] ?? 0) as int,
      verified: (json['verified'] ?? false) as bool,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: (json['phone'] ?? '') as String,
      lastDonation: (json['lastDonation'] as Timestamp?)?.toDate(),
      showPhone: (json['showPhone'] ?? true) as bool,
    );
  }
}