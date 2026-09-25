import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.bloodGroup,
    required this.phone,
    this.isDonor = true,
    this.verified = false,
    this.donations = 0,
    this.available = true,
    this.latitude,
    this.longitude,
    this.lastDonation,
    this.showPhone = true,
    this.banned = false,
  });

  final String uid;
  final String email;
  final String name;
  final String bloodGroup;
  final String phone;
  final bool isDonor;
  final bool verified;
  final int donations;
  final bool available;
  final double? latitude;
  final double? longitude;
  final DateTime? lastDonation;
  final bool showPhone;
  final bool banned;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: (json['email'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      bloodGroup: (json['bloodGroup'] ?? 'O+') as String,
      phone: (json['phone'] ?? '') as String,
      isDonor: (json['isDonor'] ?? true) as bool,
      verified: (json['verified'] ?? false) as bool,
      donations: (json['donations'] ?? 0) as int,
      available: (json['available'] ?? true) as bool,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastDonation: (json['lastDonation'] as Timestamp?)?.toDate(),
      showPhone: (json['showPhone'] ?? true) as bool,
      banned: (json['banned'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'name': name,
    'bloodGroup': bloodGroup,
    'phone': phone,
    'isDonor': isDonor,
    'verified': verified,
    'donations': donations,
    'available': available,
    'latitude': latitude,
    'longitude': longitude,
    'lastDonation': lastDonation,
    'showPhone': showPhone,
    'banned': banned,
  };
}
