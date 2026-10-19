import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/card.dart';
import 'cache_file.dart';

class _Glossary {
  _Glossary(String pattern, this.thai, {bool ci = false})
      : re = RegExp(pattern, caseSensitive: !ci);
  final RegExp re;
  final String thai;
}

/// แปลความสามารถของการ์ดเป็นภาษาไทย
///
/// - ชื่อการ์ดที่อยู่ในเครื่องหมายคำพูด "..." จะคงเป็นภาษาอังกฤษ
/// - ศัพท์เฉพาะของเกม (Special Summon, Graveyard ฯลฯ) ใช้คำไทยตามพจนานุกรมด้านล่าง
/// - ที่เหลือแปลผ่าน Google Translate endpoint และแคชผลไว้ในเครื่อง
class TranslationService {
  final Map<String, String> _cache = {};
  File? _file;
  Timer? _saveTimer;

  static final List<_Glossary> _glossary = [
    _Glossary(r'\bSpecial Summon(?:s|ed|ing)?\b', 'อัญเชิญพิเศษ'),
    _Glossary(r'\bNormal Summon(?:s|ed|ing)?\b', 'อัญเชิญปกติ'),
    _Glossary(r'\bTribute Summon(?:s|ed|ing)?\b', 'อัญเชิญแบบสังเวย'),
    _Glossary(r'\bFlip Summon(?:s|ed|ing)?\b', 'อัญเชิญแบบพลิก'),
    _Glossary(r'\bFusion Summon(?:s|ed|ing)?\b', 'อัญเชิญฟิวชัน'),
    _Glossary(r'\bSynchro Summon(?:s|ed|ing)?\b', 'อัญเชิญซินโคร'),
    _Glossary(r'\bXyz Summon(?:s|ed|ing)?\b', 'อัญเชิญเอ็กซ์ซี'),
    _Glossary(r'\bRitual Summon(?:s|ed|ing)?\b', 'อัญเชิญพิธีกรรม'),
    _Glossary(r'\bExtra Deck\b', 'เอ็กซ์ตร้าเด็ค'),
    _Glossary(r'\bGraveyard\b', 'สุสาน'),
    _Glossary(r'\bDraw Phase\b', 'ดรอว์เฟส'),
    _Glossary(r'\bStandby Phase\b', 'สแตนด์บายเฟส'),
    _Glossary(r'\bMain Phase(?: 1| 2)?\b', 'เมนเฟส'),
    _Glossary(r'\bBattle Phase\b', 'แบทเทิลเฟส'),
    _Glossary(r'\bEnd Phase\b', 'เอ็นด์เฟส'),
    _Glossary(r'\bDamage Step\b', 'ดาเมจสเต็ป'),
    _Glossary(r'\bDamage Calculation\b', 'การคำนวณดาเมจ'),
    _Glossary(r'\bLife Points?\b', 'ไลฟ์พอยต์'),
    _Glossary(r'\bAttack Position\b', 'ท่าโจมตี'),
    _Glossary(r'\bDefense Position\b', 'ท่าป้องกัน'),
    _Glossary(r'\bface-up\b', 'หงายหน้า', ci: true),
    _Glossary(r'\bface-down\b', 'คว่ำหน้า', ci: true),
    _Glossary(r'\bbanish(?:es|ed|ing)?\b', 'ตัดออกจากเกม', ci: true),
    _Glossary(r'\bTribut(?:e|es|ed|ing)\b', 'สังเวย'),
    _Glossary(r'\bSpell Cards?\b', 'การ์ดเวทมนตร์'),
    _Glossary(r'\bTrap Cards?\b', 'การ์ดกับดัก'),
    _Glossary(r'\bMonster Cards?\b', 'การ์ดมอนสเตอร์'),
    _Glossary(r'\bSpells?\b', 'เวทมนตร์'),
    _Glossary(r'\bTraps?\b', 'กับดัก'),
    _Glossary(r'\bMonsters?\b', 'มอนสเตอร์'),
    _Glossary(r'\bDeck\b', 'เด็ค'),
    _Glossary(r'\bhand\b', 'มือ', ci: true),
    _Glossary(r'\bLevel\b', 'เลเวล'),
    _Glossary(r'\bRank\b', 'แรงก์'),
    _Glossary(r'\bATK\b', 'ATK'),
    _Glossary(r'\bDEF\b', 'DEF'),
    _Glossary(r'\bLP\b', 'LP'),
  ];

  Future<void> load() async {
    try {
      _file = await cacheFile('th_translations.json');
      if (_file != null && await _file!.exists()) {
        final m = jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
        m.forEach((k, v) => _cache[k] = v as String);
      }
    } catch (_) {}
  }

  bool isCached(YgoCard c) => _cache.containsKey('${c.id}');

  Future<String> translateCard(YgoCard c, {bool force = false}) async {
    final key = '${c.id}';
    if (!force && _cache.containsKey(key)) return _cache[key]!;
    final th = await translate(c.desc);
    _cache[key] = th;
    _scheduleSave();
    return th;
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      try {
        await _file?.writeAsString(jsonEncode(_cache));
      } catch (_) {}
    });
  }

  Future<String> translate(String text) async {
    if (text.trim().isEmpty) return text;
    final protected = _protect(text);
    final out = await _google(protected.text);
    final restored = _restore(out, protected.map);
    if (restored != null) return restored;
    // placeholder หาย: แปลข้อความดิบแทน
    return _google(text);
  }

  // ---------- placeholder ----------

  ({String text, Map<int, String> map}) _protect(String input) {
    final map = <int, String>{};
    var i = 0;
    String put(String value) {
      final id = i++;
      map[id] = value;
      return ' ZX${id}ZX ';
    }

    // 1) ชื่อการ์ดในเครื่องหมายคำพูด คงเป็นอังกฤษ
    var text = input.replaceAllMapped(
      RegExp(r'"([^"]+)"'),
      (m) => put('"${m[1]}"'),
    );
    // 2) ศัพท์เฉพาะของเกม
    for (final g in _glossary) {
      text = text.replaceAllMapped(g.re, (m) => put(g.thai));
    }
    return (text: text, map: map);
  }

  String? _restore(String translated, Map<int, String> map) {
    if (map.isEmpty) return translated;
    final found = <int>{};
    var out = translated.replaceAllMapped(
      RegExp(r'\s*Z\s?X\s?(\d+)\s?Z\s?X\s*', caseSensitive: false),
      (m) {
        final id = int.parse(m[1]!);
        final v = map[id];
        if (v == null) return m[0]!;
        found.add(id);
        return ' $v ';
      },
    );
    if (found.length != map.length) return null;
    out = out
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .replaceAllMapped(RegExp(r' +([,.:;)!?])'), (m) => m[1]!)
        .replaceAll(RegExp(r'\n +'), '\n')
        .trim();
    return out;
  }

  // ---------- Google Translate (gtx) ----------

  Future<String> _google(String q) async {
    final parts = _chunks(q, 1500);
    final buf = StringBuffer();
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) buf.write('\n');
      buf.write(await _googleOne(parts[i]));
    }
    return buf.toString();
  }

  List<String> _chunks(String s, int max) {
    if (s.length <= max) return [s];
    final out = <String>[];
    var cur = StringBuffer();
    for (final line in s.split('\n')) {
      if (cur.length + line.length + 1 > max && cur.isNotEmpty) {
        out.add(cur.toString());
        cur = StringBuffer();
      }
      if (cur.isNotEmpty) cur.write('\n');
      cur.write(line);
    }
    if (cur.isNotEmpty) out.add(cur.toString());
    return out;
  }

  Future<String> _googleOne(String q) async {
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gtx',
      'sl': 'en',
      'tl': 'th',
      'dt': 't',
      'q': q,
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('แปลไม่สำเร็จ (HTTP ${res.statusCode})');
    }
    final j = jsonDecode(utf8.decode(res.bodyBytes));
    final segs = (j as List)[0] as List;
    return segs.map((s) => (s as List)[0]?.toString() ?? '').join();
  }
}
