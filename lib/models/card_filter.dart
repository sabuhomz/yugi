import 'card.dart';

enum SortKey { name, atk, def, level }

const sortLabels = {
  SortKey.name: 'ชื่อ',
  SortKey.atk: 'ATK',
  SortKey.def: 'DEF',
  SortKey.level: 'เลเวล',
};

const catLabels = {
  'monster': 'มอนสเตอร์',
  'extra': 'เอ็กซ์ตร้าเด็ค',
  'spell': 'เวทมนตร์',
  'trap': 'กับดัก',
};

const srcLabels = {'dl': 'Duel Links', 'sd': 'Speed Duel (TCG)'};

const subTypes = [
  'Normal',
  'Effect',
  'Flip',
  'Tuner',
  'Ritual',
  'Fusion',
  'Synchro',
  'XYZ',
  'Link',
];

const attributes = ['DARK', 'LIGHT', 'EARTH', 'WATER', 'FIRE', 'WIND', 'DIVINE'];

class CardFilter {
  Set<String> cats = {};
  Set<String> subs = {};
  Set<String> attrs = {};
  Set<String> races = {};
  Set<int> levels = {};
  Set<String> srcs = {}; // dl, sd
  SortKey sort = SortKey.name;
  bool asc = true;

  bool get active =>
      cats.isNotEmpty ||
      subs.isNotEmpty ||
      attrs.isNotEmpty ||
      races.isNotEmpty ||
      levels.isNotEmpty ||
      srcs.isNotEmpty;

  CardFilter copy() => CardFilter()
    ..cats = {...cats}
    ..subs = {...subs}
    ..attrs = {...attrs}
    ..races = {...races}
    ..levels = {...levels}
    ..srcs = {...srcs}
    ..sort = sort
    ..asc = asc;

  void clear() {
    cats.clear();
    subs.clear();
    attrs.clear();
    races.clear();
    levels.clear();
    srcs.clear();
  }

  bool matches(YgoCard c) {
    if (cats.isNotEmpty) {
      final k = c.isSpell
          ? 'spell'
          : c.isTrap
              ? 'trap'
              : c.isExtra
                  ? 'extra'
                  : 'monster';
      if (!cats.contains(k)) return false;
    }
    if (subs.isNotEmpty) {
      final t = c.type.toLowerCase();
      if (!subs.any((s) => t.contains(s.toLowerCase()))) return false;
    }
    if (srcs.isNotEmpty &&
        !((srcs.contains('dl') && c.inDl) || (srcs.contains('sd') && c.inSd))) {
      return false;
    }
    if (attrs.isNotEmpty && !attrs.contains(c.attribute)) return false;
    if (races.isNotEmpty && !races.contains(c.race)) return false;
    if (levels.isNotEmpty && !levels.contains(c.level)) return false;
    return true;
  }

  List<YgoCard> apply(List<YgoCard> all, String query) {
    final q = query.trim().toLowerCase();
    final out = all
        .where((c) => (q.isEmpty || c.name.toLowerCase().contains(q)) && matches(c))
        .toList();
    int cmp(YgoCard a, YgoCard b) {
      switch (sort) {
        case SortKey.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case SortKey.atk:
          return (a.atk ?? -2).compareTo(b.atk ?? -2);
        case SortKey.def:
          return (a.def ?? -2).compareTo(b.def ?? -2);
        case SortKey.level:
          return (a.level ?? -1).compareTo(b.level ?? -1);
      }
    }

    out.sort((a, b) {
      final r = cmp(a, b);
      final v = r != 0 ? r : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return asc ? v : (r != 0 ? -r : v);
    });
    return out;
  }
}
