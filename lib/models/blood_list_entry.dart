import 'package:cloud_firestore/cloud_firestore.dart';

/// রক্তদাতা তালিকায় (bloodList) একজন ব্যক্তির এন্ট্রি।
/// — ম্যানেজার/কো-অ্যাডমিন নাম ও একাধিক নম্বর যোগ করতে পারে
/// — অ্যাডমিন 'verified' টগল করে নম্বর ভেরিফাই করতে পারে
class BloodListEntry {
  const BloodListEntry({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.phones,
    this.email = '',
    this.area = '',
    this.note = '',
    this.addedBy = '',
    this.verified = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String bloodGroup;

  /// একাধিক নম্বর (মোবাইল/ল্যান্ডলাইন)
  final List<String> phones;
  final String email;
  final String area;
  final String note;
  final String addedBy;

  /// অ্যাডমিন ভেরিফাই করেছে কি না
  final bool verified;
  final DateTime? createdAt;

  factory BloodListEntry.fromJson(String id, Map<String, dynamic> json) {
    final rawPhones = (json['phones'] as List<dynamic>?) ?? const [];
    return BloodListEntry(
      id: id,
      name: (json['name'] ?? '') as String,
      bloodGroup: (json['bloodGroup'] ?? 'O+') as String,
      phones: rawPhones.map((e) => e.toString()).toList(),
      email: (json['email'] ?? '') as String,
      area: (json['area'] ?? '') as String,
      note: (json['note'] ?? '') as String,
      addedBy: (json['addedBy'] ?? '') as String,
      verified: (json['verified'] ?? false) as bool,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'bloodGroup': bloodGroup,
    'phones': phones,
    'email': email,
    'area': area,
    'note': note,
    'addedBy': addedBy,
    'verified': verified,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
  };
}
