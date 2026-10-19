class Deck {
  Deck({
    required this.id,
    required this.name,
    List<int>? main,
    List<int>? extra,
    DateTime? updated,
  })  : main = main ?? [],
        extra = extra ?? [],
        updated = updated ?? DateTime.now();

  final String id;
  String name;
  final List<int> main;
  final List<int> extra;
  DateTime updated;

  int count(int cardId) =>
      main.where((e) => e == cardId).length +
      extra.where((e) => e == cardId).length;

  bool get valid => main.length >= 20 && main.length <= 30;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'main': main,
        'extra': extra,
        'updated': updated.toIso8601String(),
      };

  factory Deck.fromJson(Map<String, dynamic> j) => Deck(
        id: j['id'] as String,
        name: (j['name'] ?? 'Deck') as String,
        main: ((j['main'] ?? []) as List).map((e) => (e as num).toInt()).toList(),
        extra:
            ((j['extra'] ?? []) as List).map((e) => (e as num).toInt()).toList(),
        updated: DateTime.tryParse((j['updated'] ?? '') as String),
      );
}
