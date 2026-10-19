import 'package:shared_preferences/shared_preferences.dart';

/// จำว่าผู้ใช้ดูหน้า onboarding แล้วหรือยัง (เก็บในเครื่อง)
class OnboardingStore {
  static const _key = 'onboarding_done_v1';

  static Future<bool> isDone() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDone() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key, true);
    } catch (_) {}
  }
}
