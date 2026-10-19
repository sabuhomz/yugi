import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/card.dart';
import 'cache_file.dart';

/// โหลดการ์ดจาก YGOPRODeck API ทั้ง Duel Links และ Speed Duel แล้วรวมกัน
///
/// - ตรวจ `checkDBVer.php` ทุกครั้งที่เปิดแอป ถ้าฐานข้อมูลอัปเดตจะดึงใหม่อัตโนมัติ
///   (จึงได้การ์ดใหม่ตามแพตช์ล่าสุดเท่าที่ YGOPRODeck อัปเดต)
/// - เก็บแคชในเครื่อง ใช้ออฟไลน์ได้
class CardRepository extends ChangeNotifier {
  static const _base = 'https://db.ygoprodeck.com/api/v7';
  static const dlUrl = '$_base/cardinfo.php?format=Duel%20Links';
  static const sdUrl = '$_base/cardinfo.php?format=Speed%20Duel';
  static const verUrl = '$_base/checkDBVer.php';

  List<YgoCard> cards = [];
  Map<int, YgoCard> byId = {};
  List<String> races = [];
  bool loading = true;
  String? error;
  String? dbVersion;
  int dlCount = 0;
  int sdCount = 0;

  Future<String?> _get(String url, {int timeout = 120}) async {
    try {
      final r =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: timeout));
      if (r.statusCode == 200) return utf8.decode(r.bodyBytes);
    } catch (_) {}
    return null;
  }

  Future<String?> _remoteVersion() async {
    final b = await _get(verUrl, timeout: 10);
    if (b == null) return null;
    try {
      final j = jsonDecode(b);
      final m = j is List ? j.first : j;
      final v = '${m['database_version']}|${m['last_update'] ?? m['date'] ?? ''}';
      return v;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _read(File? f) async {
    try {
      if (f != null && await f.exists()) return await f.readAsString();
    } catch (_) {}
    return null;
  }

  Future<void> load({bool force = false}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final cf = await cacheFile('ygo_cards_v2.json');
      final vf = await cacheFile('ygo_cards_v2.ver');
      final cached = await _read(cf);
      final localVer = await _read(vf);

      String? body;
      var ver = localVer;
      if (cached != null && !force) {
        final remote = await _remoteVersion();
        var fresh = false;
        if (remote != null) {
          fresh = remote == localVer;
        } else if (cf != null) {
          // ตรวจเวอร์ชันไม่ได้: ถ้าแคชอายุไม่เกิน 1 วันก็ใช้ต่อ
          try {
            fresh = DateTime.now().difference(await cf.lastModified()).inHours < 24;
          } catch (_) {}
        }
        if (fresh) {
          body = cached;
        } else {
          ver = remote;
        }
      } else {
        ver = await _remoteVersion();
      }

      if (body == null) {
        final res = await Future.wait([_get(dlUrl), _get(sdUrl)]);
        final dl = res[0] ?? '';
        final sd = res[1] ?? '';
        if (dl.isEmpty && sd.isEmpty) {
          if (cached != null) {
            body = cached; // ออฟไลน์: ใช้แคชเก่า
          } else {
            throw Exception('เชื่อมต่อ YGOPRODeck ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่');
          }
        } else {
          final merged = await compute(mergeBodies, [dl, sd]);
          body = merged;
          try {
            await cf?.writeAsString(merged);
            await vf?.writeAsString(ver ?? DateTime.now().toIso8601String());
          } catch (_) {}
        }
      }

      dbVersion = ver;
      final text = body!;
      final parsed = await compute(parseCards, text);
      cards = parsed;
      byId = {for (final c in parsed) c.id: c};
      dlCount = parsed.where((c) => c.inDl).length;
      sdCount = parsed.where((c) => c.inSd).length;
      races = parsed.map((c) => c.race).whereType<String>().toSet().toList()
        ..sort();
    } catch (e) {
      error = '$e'.replaceFirst('Exception: ', '');
    }
    loading = false;
    notifyListeners();
  }
}
