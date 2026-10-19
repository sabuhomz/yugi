import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card.dart';
import '../models/deck.dart';

enum AddResult { ok, mainFull, extraFull, tooManyCopies, overLimit }

const mainMin = 20;
const mainMax = 30;
const extraMax = 9;
const copyMax = 3;

String addMessage(AddResult r, YgoCard c) {
  switch (r) {
    case AddResult.ok:
      return 'เพิ่ม ${c.name} แล้ว';
    case AddResult.mainFull:
      return 'เด็คหลักเต็มแล้ว ($mainMax ใบ)';
    case AddResult.extraFull:
      return 'เอ็กซ์ตร้าเด็คเต็มแล้ว ($extraMax ใบ)';
    case AddResult.tooManyCopies:
      return 'ใส่การ์ดชื่อเดียวกันได้ไม่เกิน $copyMax ใบ';
    case AddResult.overLimit:
      return 'การ์ดนี้ถูกตั้งข้อจำกัดไว้ (ปรับได้ที่หน้ารายละเอียดการ์ด)';
  }
}

class DeckStore extends ChangeNotifier {
  static const _key = 'decks_v1';
  final List<Deck> decks = [];

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      decks
        ..clear()
        ..addAll(list.map((e) => Deck.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      // ข้อมูลเสีย ให้เริ่มใหม่
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(decks.map((d) => d.toJson()).toList()));
    } catch (_) {}
  }

  void _changed(Deck? d) {
    d?.updated = DateTime.now();
    notifyListeners();
    _save();
  }

  Deck? byId(String id) {
    for (final d in decks) {
      if (d.id == id) return d;
    }
    return null;
  }

  Deck create(String name) {
    final d = Deck(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? 'My Deck' : name.trim(),
    );
    decks.insert(0, d);
    _changed(d);
    return d;
  }

  Deck duplicate(Deck src) {
    final d = Deck(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '${src.name} (copy)',
      main: [...src.main],
      extra: [...src.extra],
    );
    decks.insert(0, d);
    _changed(d);
    return d;
  }

  void rename(Deck d, String name) {
    if (name.trim().isEmpty) return;
    d.name = name.trim();
    _changed(d);
  }

  void delete(Deck d) {
    decks.remove(d);
    _changed(null);
  }

  void clear(Deck d) {
    d.main.clear();
    d.extra.clear();
    _changed(d);
  }

  /// [max] คือจำนวนใบสูงสุดของการ์ดใบนี้ (ค่าที่ผู้ใช้ตั้งเองจาก LimitStore)
  AddResult add(Deck d, YgoCard c, {int max = copyMax}) {
    if (d.count(c.id) >= max) {
      return max < copyMax ? AddResult.overLimit : AddResult.tooManyCopies;
    }
    if (c.isExtra) {
      if (d.extra.length >= extraMax) return AddResult.extraFull;
      d.extra.add(c.id);
    } else {
      if (d.main.length >= mainMax) return AddResult.mainFull;
      d.main.add(c.id);
    }
    _changed(d);
    return AddResult.ok;
  }

  /// เอาการ์ดนั้นออก 1 ใบ (ใบล่าสุด)
  void removeOne(Deck d, YgoCard c) {
    final list = c.isExtra ? d.extra : d.main;
    final i = list.lastIndexOf(c.id);
    if (i >= 0) {
      list.removeAt(i);
      _changed(d);
    }
  }

  void removeAt(Deck d, bool extra, int index) {
    final list = extra ? d.extra : d.main;
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      _changed(d);
    }
  }

  /// เรียงเด็ค: มอนสเตอร์ (เลเวลสูง→ต่ำ) → เวทมนตร์ → กับดัก
  void sortDeck(Deck d, Map<int, YgoCard> byId) {
    int cmp(int a, int b) {
      final ca = byId[a];
      final cb = byId[b];
      if (ca == null || cb == null) return a.compareTo(b);
      final k = ca.kindRank.compareTo(cb.kindRank);
      if (k != 0) return k;
      final l = (cb.level ?? 0).compareTo(ca.level ?? 0);
      if (l != 0) return l;
      return ca.name.toLowerCase().compareTo(cb.name.toLowerCase());
    }

    d.main.sort(cmp);
    d.extra.sort(cmp);
    _changed(d);
  }
}
