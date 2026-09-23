class BloodCompat {
  BloodCompat._();

  static const List<String> groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

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
  }) =>
      (compatibleDonorsFor[receiverGroup] ?? const []).contains(donorGroup);
}