import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// রক্তদাতা তালিকার কার্ডে "মাছ-সাঁতার" অ্যানিমেশনের on/off (settings থেকে)।
class AnimationPref {
  AnimationPref._();
  static final AnimationPref instance = AnimationPref._();

  static const String key = 'roster_animation';

  /// সব কার্ড অ্যানিমেশন উইজেট শোনে; ডিফল্ট চালু।
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(key) ?? true;
  }

  Future<void> set(bool v) async {
    enabled.value = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, v);
  }
}
