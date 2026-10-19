import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ข้อจำกัดจำนวนใบต่อการ์ดที่ผู้ใช้ตั้งเอง (3 = ปกติ, 2, 1, 0 = ห้ามใช้)
///
/// YGOPRODeck ไม่มีรายการห้าม/จำกัดของ Speed Duel และ Duel Links
/// จึงให้ผู้ใช้ตั้งเองตามที่เกมแจ้ง แล้วตัวตรวจเด็คจะใช้ค่าเหล่านี้
class LimitStore extends ChangeNotifier {
  static const _key = 'card_limits_v1';
  final Map<int, int> _m = {};

  int maxFor(int id) => _m[id] ?? 3;
  int get count => _m.length;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _m
        ..clear()
        ..addAll(j.map((k, v) => MapEntry(int.parse(k), (v as num).toInt())));
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(_m.map((k, v) => MapEntry('$k', v))));
    } catch (_) {}
  }

  void set(int id, int max) {
    if (max >= 3) {
      _m.remove(id);
    } else {
      _m[id] = max;
    }
    notifyListeners();
    _save();
  }
}
