class BloodCompat {
  BloodCompat._();

  static const List<String> groups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  /// কোন ডোনার কোন রোগীকে দিতে পারবে (রিসিভারের গ্রুপ → কম্প্যাটিবল ডোনার)।
  static const Map<String, List<String>> compatibleDonorsFor = {
    'O-': ['O-'],
    'O+': ['O+', 'O-'],
    'A-': ['A-', 'O-'],
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'AB-': ['AB-', 'A-', 'B-', 'O-'],
    'AB+': ['AB+', 'AB-', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-'],
  };

  static bool canDonateTo({
    required String donorGroup,
    required String receiverGroup,
  }) => (compatibleDonorsFor[receiverGroup] ?? const []).contains(donorGroup);
}

/// রক্তদানের ৯০ দিনের নিয়ম — কবে আবার রক্ত দেওয়া যাবে।
class DonationEligibility {
  DonationEligibility._();

  static const int gapDays = 90;

  /// (eligible, eligibleFrom, remainingDays)
  /// - lastDonation null → এখনই পারবেন (eligibleFrom = null)
  /// - remainingDays দিতে পেলে ০; বাকি থাকলে ইতিবাচক
  static ({bool eligible, DateTime? eligibleFrom, int remaining}) forUser(
    DateTime? lastDonation,
  ) {
    if (lastDonation == null) {
      return (eligible: true, eligibleFrom: null, remaining: 0);
    }
    final from = lastDonation.add(const Duration(days: gapDays));
    final remaining = from.difference(DateTime.now()).inDays;
    return (
      eligible: remaining <= 0,
      eligibleFrom: from,
      remaining: remaining < 0 ? 0 : remaining,
    );
  }
}
