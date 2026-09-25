import 'blood_compat.dart';

/// Donor-কে একটি রিকোয়েস্ট (রোগীর গ্রুপ) বনাম কতটা ভালো ম্যাচ তা 0–100 স্কোর।
/// কম্প্যাটিবল না হলে স্কোর 0 (সর্বদা বাতিল)।
class MatchScore {
  const MatchScore({
    required this.compatible,
    required this.total,
    required this.groupPoints,
    required this.distancePoints,
    required this.availabilityPoints,
    required this.verifiedPoints,
    required this.experiencePoints,
  });

  final bool compatible;
  final int total;
  final int groupPoints;
  final int distancePoints;
  final int availabilityPoints;
  final int verifiedPoints;
  final int experiencePoints;
}

class MatchScorer {
  MatchScorer._();

  static MatchScore compute({
    required String receiverGroup,
    required String donorGroup,
    double? distanceKm,
    bool available = true,
    bool verified = false,
    int donations = 0,
  }) {
    final compatible = BloodCompat.canDonateTo(
      donorGroup: donorGroup,
      receiverGroup: receiverGroup,
    );
    if (!compatible) {
      return MatchScore(
        compatible: false,
        total: 0,
        groupPoints: 0,
        distancePoints: 0,
        availabilityPoints: 0,
        verifiedPoints: 0,
        experiencePoints: 0,
      );
    }

    // 30 max
    final groupPoints = donorGroup == receiverGroup ? 30 : 26;

    // 30 max — ৫০km-এর বেশি হলে ০
    final dist = (distanceKm ?? 9999).clamp(0, 50).toDouble();
    final distancePoints = (30 * (1 - dist / 50)).round();

    // 20 max
    final availabilityPoints = available ? 20 : 0;

    // 15 max
    final verifiedPoints = verified ? 15 : 0;

    // 5 max — বেশি ডোনেশন = বেশি অভিজ্ঞতা
    final experiencePoints = donations.clamp(0, 10) ~/ 2;

    final total =
        groupPoints +
        distancePoints +
        availabilityPoints +
        verifiedPoints +
        experiencePoints;

    return MatchScore(
      compatible: true,
      total: total,
      groupPoints: groupPoints,
      distancePoints: distancePoints,
      availabilityPoints: availabilityPoints,
      verifiedPoints: verifiedPoints,
      experiencePoints: experiencePoints,
    );
  }

  static String label(int score) {
    if (score >= 85) return 'নিখুঁত ম্যাচ';
    if (score >= 70) return 'খুব ভালো ম্যাচ';
    if (score >= 55) return 'ভালো ম্যাচ';
    return 'সাধারণ ম্যাচ';
  }
}
