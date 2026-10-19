import 'dart:convert';

class YgoCard {
  YgoCard({
    required this.id,
    required this.name,
    required this.type,
    required this.desc,
    required this.imageUrl,
    required this.imageSmall,
    this.atk,
    this.def,
    this.level,
    this.linkval,
    this.race,
    this.attribute,
    this.archetype,
    this.inDl = false,
    this.inSd = false,
  });

  final int id;
  final String name;
  final String type;
  final String desc;
  final String imageUrl;
  final String imageSmall;
  final int? atk;
  final int? def;
  final int? level;
  final int? linkval;
  final String? race;
  final String? attribute;
  final String? archetype;
  final bool inDl; // อยู่ใน Duel Links
  final bool inSd; // อยู่ใน Speed Duel (TCG)

  factory YgoCard.fromJson(Map<String, dynamic> j,
      {bool dl = false, bool sd = false}) {
    final id = (j['id'] as num).toInt();
    String big = '';
    String small = '';
    final imgs = j['card_images'];
    if (imgs is List && imgs.isNotEmpty && imgs.first is Map) {
      final m = imgs.first as Map;
      big = (m['image_url'] ?? '') as String;
      small = (m['image_url_small'] ?? big) as String;
    }
    if (big.isEmpty) big = 'https://images.ygoprodeck.com/images/cards/$id.jpg';
    if (small.isEmpty) {
      small = 'https://images.ygoprodeck.com/images/cards_small/$id.jpg';
    }
    return YgoCard(
      id: id,
      name: (j['name'] ?? '') as String,
      type: (j['type'] ?? '') as String,
      desc: (j['desc'] ?? '') as String,
      imageUrl: big,
      imageSmall: small,
      atk: (j['atk'] as num?)?.toInt(),
      def: (j['def'] as num?)?.toInt(),
      level: (j['level'] as num?)?.toInt(),
      linkval: (j['linkval'] as num?)?.toInt(),
      race: j['race'] as String?,
      attribute: j['attribute'] as String?,
      archetype: j['archetype'] as String?,
      inDl: dl,
      inSd: sd,
    );
  }

  bool get isMonster => type.contains('Monster');
  bool get isSpell => type == 'Spell Card';
  bool get isTrap => type == 'Trap Card';
  bool get isSkill => type == 'Skill Card';
  bool get isNormal => type.contains('Normal');
  bool get isXyz => type.contains('XYZ');
  bool get isLink => type.contains('Link');

  /// การ์ดที่ต้องอยู่ใน Extra Deck
  bool get isExtra =>
      isMonster &&
      (type.contains('Fusion') ||
          type.contains('Synchro') ||
          type.contains('XYZ') ||
          type.contains('Link'));

  /// 0 = monster, 1 = spell, 2 = trap (ใช้เรียงในเด็ค)
  int get kindRank => isSpell ? 1 : (isTrap ? 2 : 0);
}

/// รวมผลจาก format=Duel Links และ format=Speed Duel เป็นก้อนเดียว (รันใน isolate)
/// args[0] = body ของ Duel Links, args[1] = body ของ Speed Duel (ว่างได้ถ้าโหลดไม่สำเร็จ)
String mergeBodies(List<String> args) {
  final merged = <int, Map<String, dynamic>>{};
  final dl = <int>[];
  final sd = <int>[];
  void add(String body, List<int> ids) {
    if (body.isEmpty) return;
    final data = (jsonDecode(body) as Map<String, dynamic>)['data'] as List;
    for (final e in data) {
      final m = e as Map<String, dynamic>;
      final id = (m['id'] as num).toInt();
      merged.putIfAbsent(id, () => m);
      ids.add(id);
    }
  }

  add(args[0], dl);
  add(args[1], sd);
  return jsonEncode({'dl': dl, 'sd': sd, 'data': merged.values.toList()});
}

/// ใช้กับ compute() เพื่อ parse JSON ขนาดใหญ่นอก main isolate
List<YgoCard> parseCards(String body) {
  final root = jsonDecode(body) as Map<String, dynamic>;
  final dl = ((root['dl'] ?? []) as List).map((e) => (e as num).toInt()).toSet();
  final sd = ((root['sd'] ?? []) as List).map((e) => (e as num).toInt()).toSet();
  final data = root['data'] as List;
  final cards = data
      .map((e) {
        final m = e as Map<String, dynamic>;
        final id = (m['id'] as num).toInt();
        return YgoCard.fromJson(m, dl: dl.contains(id), sd: sd.contains(id));
      })
      .where((c) => !c.isSkill)
      .toList();
  cards.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return cards;
}

String statText(int? v) => v == null ? '-' : (v < 0 ? '?' : '$v');
