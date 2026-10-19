import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../services/card_repository.dart';
import '../services/deck_store.dart';
import '../theme/duel_theme.dart';
import '../widgets/card_image.dart';
import 'card_detail_screen.dart';

/// ตัวจำลองการจั่วการ์ดจากเด็คหลัก + โอกาสเปิดมือแรกแบบคำนวณจริง
class DrawSimScreen extends StatefulWidget {
  const DrawSimScreen({super.key, required this.deckId});
  final String deckId;

  @override
  State<DrawSimScreen> createState() => _DrawSimScreenState();
}

class _DrawSimScreenState extends State<DrawSimScreen> {
  final _rnd = Random();
  int _handSize = 4;
  List<YgoCard> _pool = [];
  int _dealNo = 0;
  String _poolSig = '';
  List<YgoCard> _pile = [];
  List<YgoCard> _hand = [];
  String _deckName = '';

  @override
  void initState() {
    super.initState();
    _pool = _buildPool();
    _poolSig = _sig(_pool);
    _newHand();
  }

  /// สร้างรายการการ์ดจากเด็คหลักตามข้อมูลล่าสุด (เรียกซ้ำเมื่อข้อมูลเปลี่ยน)
  List<YgoCard> _buildPool() {
    final repo = context.read<CardRepository>();
    final deck = context.read<DeckStore>().byId(widget.deckId);
    _deckName = deck?.name ?? '';
    return [
      for (final id in deck?.main ?? const <int>[])
        if (repo.byId[id] != null) repo.byId[id]!,
    ];
  }

  String _sig(List<YgoCard> l) => l.map((c) => c.id).join(',');

  void _reshuffle() {
    if (_pool.isEmpty) {
      showToast(context,
          'ยังไม่มีการ์ดให้สุ่ม (เด็คหลักว่าง หรือข้อมูลการ์ดยังโหลดไม่เสร็จ)');
      return;
    }
    setState(_newHand);
    showToast(context, 'สุ่มมือใหม่แล้ว (ครั้งที่ $_dealNo)');
  }

  void _drawOne() {
    if (_pile.isEmpty) {
      showToast(context, 'ไม่มีการ์ดเหลือในเด็คแล้ว');
      return;
    }
    setState(() => _hand.add(_pile.removeAt(0)));
  }

  void _newHand() {
    _dealNo++;
    final all = [..._pool]..shuffle(_rnd);
    final n = min(_handSize, all.length);
    _hand = all.sublist(0, n).toList();
    _pile = all.sublist(n).toList();
  }

  // ความน่าจะเป็นที่ไม่เจอการ์ดกลุ่ม k ใบ เมื่อจั่ว h ใบจากเด็ค n ใบ (hypergeometric)
  static double _pNone(int n, int k, int h) {
    if (h > n) h = n;
    if (n - k < h) return 0;
    var p = 1.0;
    for (var i = 0; i < h; i++) {
      p *= (n - k - i) / (n - i);
    }
    return p;
  }

  static double _pAny(int n, int k, int h) => k <= 0 ? 0 : 1 - _pNone(n, k, h);

  @override
  Widget build(BuildContext context) {
    // ตามข้อมูลสด: ถ้าการ์ดเพิ่งโหลดเสร็จหรือเด็คเปลี่ยน ให้แจกมือใหม่ให้อัตโนมัติ
    context.watch<CardRepository>();
    context.watch<DeckStore>();
    final fresh = _buildPool();
    final sig = _sig(fresh);
    if (sig != _poolSig) {
      _pool = fresh;
      _poolSig = sig;
      _newHand();
    }
    return Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: SafeArea(
          child: Column(
            children: [
              DuelTitleBar(
                title: 'Draw Test · $_deckName',
                icon: Icons.casino,
                onBack: () => Navigator.pop(context),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _handPanel(),
                    const SizedBox(height: 12),
                    _controls(),
                    if (_pool.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _stats(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handPanel() {
    return DuelPanel(
      borderColor: DL.cyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('มือ (${_hand.length} ใบ)',
                  style: const TextStyle(
                      color: DL.gold, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              Text('เหลือในเด็ค ${_pile.length} ใบ',
                  style: const TextStyle(color: DL.muted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          if (_pool.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('เด็คหลักยังไม่มีการ์ด เพิ่มการ์ดก่อนแล้วลองใหม่',
                    style: TextStyle(color: DL.muted)),
              ),
            )
          else
            GridView.count(
              key: ValueKey(_dealNo),
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 59 / 86,
              children: [
                for (var i = 0; i < _hand.length; i++) _handCard(i),
              ],
            ),
          if (_hand.length > _handSize)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('กรอบสีทอง = ใบที่จั่วเพิ่ม',
                  style: TextStyle(color: DL.gold, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _handCard(int i) {
    final c = _hand[i];
    final extra = i >= _handSize;
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CardDetailScreen(cards: _hand, index: i)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: extra ? DL.gold : DL.cyan.withAlpha(160),
            width: extra ? 2.2 : 1.2,
          ),
        ),
        child: CardImage(url: c.imageSmall, fit: BoxFit.fill),
      ),
    );
  }

  Widget _controls() {
    return DuelPanel(
      child: Column(
        children: [
          Row(
            children: [
              const Text('ขนาดมือเริ่มต้น', style: TextStyle(fontSize: 14)),
              const Spacer(),
              IconButton(
                onPressed: _handSize > 1
                    ? () => setState(() {
                          _handSize--;
                          _newHand();
                        })
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 28,
                child: Text('$_handSize',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: _handSize < 8
                    ? () => setState(() {
                          _handSize++;
                          _newHand();
                        })
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DuelButton(
                  label: 'สุ่มมือใหม่',
                  icon: Icons.shuffle,
                  onTap: _reshuffle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DuelButton(
                  label: 'จั่ว 1 ใบ',
                  icon: Icons.add,
                  green: true,
                  onTap: _drawOne,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stats() {
    final n = _pool.length;
    final h = min(_handSize, n);
    final monsters = _pool.where((c) => c.isMonster).length;
    final lowMonsters =
        _pool.where((c) => c.isMonster && (c.level ?? 99) <= 4).length;
    final st = _pool.where((c) => c.isSpell || c.isTrap).length;

    final counts = <int, int>{};
    final byId = <int, YgoCard>{};
    for (final c in _pool) {
      counts[c.id] = (counts[c.id] ?? 0) + 1;
      byId[c.id] = c;
    }
    final rows = counts.entries
        .map((e) => (card: byId[e.key]!, n: e.value, p: _pAny(n, e.value, h)))
        .toList()
      ..sort((a, b) {
        final r = b.p.compareTo(a.p);
        return r != 0 ? r : a.card.name.compareTo(b.card.name);
      });

    return DuelPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('โอกาสในมือแรก ($h ใบ จากเด็ค $n ใบ)',
              style: const TextStyle(
                  color: DL.cyan, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 2),
          const Text('คำนวณจากเด็คทั้งหมด ไม่ขึ้นกับมือที่สุ่มอยู่',
              style: TextStyle(color: DL.muted, fontSize: 11.5)),
          const SizedBox(height: 12),
          _bar('มีมอนสเตอร์เลเวล 1–4 อย่างน้อย 1 ใบ (อัญเชิญปกติได้ทันที)',
              _pAny(n, lowMonsters, h), DL.green),
          _bar('มือไม่มีมอนสเตอร์เลย', _pNone(n, monsters, h), DL.red),
          _bar('มีเวทมนตร์/กับดักอย่างน้อย 1 ใบ', _pAny(n, st, h), DL.purple),
          const Divider(color: DL.edge, height: 22),
          const Text('โอกาสเจอแต่ละใบอย่างน้อย 1 ใบ',
              style: TextStyle(
                  color: DL.gold, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    height: 44,
                    child: CardImage(url: r.card.imageSmall, fit: BoxFit.fill),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('${r.card.name}  ×${r.n}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Text('${(r.p * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(String label, double p, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
              Text('${(p * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: p.clamp(0.0, 1.0).toDouble(),
              minHeight: 7,
              color: color,
              backgroundColor: const Color(0xFF0A2258),
            ),
          ),
        ],
      ),
    );
  }
}
