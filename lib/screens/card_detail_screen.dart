import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/deck.dart';
import '../services/deck_store.dart';
import '../services/limit_store.dart';
import '../services/translation_service.dart';
import '../theme/duel_theme.dart';
import '../widgets/card_badges.dart';
import '../widgets/card_image.dart';

/// หน้ารายละเอียดการ์ด ปัดซ้าย/ขวาเพื่อดูใบอื่นในรายการเดียวกันได้
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({
    super.key,
    required this.cards,
    this.index = 0,
    this.deckId,
  });

  final List<YgoCard> cards;
  final int index;
  final String? deckId;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late final PageController _pc;
  late int _i;

  @override
  void initState() {
    super.initState();
    _i = widget.index.clamp(0, widget.cards.length - 1).toInt();
    _pc = PageController(initialPage: _i);
    _prefetch(_i);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  /// แปลใบก่อนหน้า/ถัดไปรอไว้ล่วงหน้า ปัดแล้วไม่ต้องรอ
  void _prefetch(int i) {
    final t = context.read<TranslationService>();
    for (final j in [i - 1, i + 1]) {
      if (j >= 0 && j < widget.cards.length && !t.isCached(widget.cards[j])) {
        t.translateCard(widget.cards[j]).catchError((_) => '');
      }
    }
  }

  void _go(int delta) {
    final to = _i + delta;
    if (to < 0 || to >= widget.cards.length) return;
    _pc.animateToPage(to,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    final c = cards[_i];
    final store = context.watch<DeckStore>();
    final limits = context.watch<LimitStore>();
    final deck = widget.deckId == null ? null : store.byId(widget.deckId!);
    final many = cards.length > 1;

    return Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: SafeArea(
          child: Column(
            children: [
              DuelTitleBar(
                title: 'Card Info',
                icon: Icons.info_outline,
                onBack: () => Navigator.pop(context),
                trailing: many
                    ? Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text('${_i + 1} / ${cards.length}',
                            style: const TextStyle(
                                color: DL.gold, fontWeight: FontWeight.w700)),
                      )
                    : null,
              ),
              Expanded(
                child: ScrollConfiguration(
                  // ให้ลากด้วยเมาส์/ทัชแพดบนเว็บและเดสก์ท็อปได้เหมือนปัดนิ้ว
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: PageView.builder(
                    controller: _pc,
                    itemCount: cards.length,
                    onPageChanged: (i) {
                      setState(() => _i = i);
                      _prefetch(i);
                    },
                    itemBuilder: (_, i) =>
                        _CardPage(key: ValueKey(cards[i].id), card: cards[i]),
                  ),
                ),
              ),
              if (many) _navStrip(),
              if (deck != null) _deckBar(context, deck, c, limits),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navStrip() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        border: const Border(top: BorderSide(color: DL.edge, width: 1.5)),
      ),
      child: Row(
        children: [
          DuelButton(
            label: 'ก่อนหน้า',
            icon: Icons.chevron_left,
            dense: true,
            onTap: _i > 0 ? () => _go(-1) : null,
          ),
          const Expanded(
            child: Text('ปัดซ้าย/ขวาเพื่อดูใบอื่น',
                textAlign: TextAlign.center,
                style: TextStyle(color: DL.muted, fontSize: 12)),
          ),
          DuelButton(
            label: 'ถัดไป',
            icon: Icons.chevron_right,
            dense: true,
            onTap: _i < widget.cards.length - 1 ? () => _go(1) : null,
          ),
        ],
      ),
    );
  }

  Widget _deckBar(
      BuildContext context, Deck deck, YgoCard c, LimitStore limits) {
    final store = context.read<DeckStore>();
    final n = deck.count(c.id);
    final max = limits.maxFor(c.id);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(190),
        border: const Border(top: BorderSide(color: DL.edge, width: 2)),
      ),
      child: Row(
        children: [
          DuelButton(
            label: '−',
            danger: true,
            onTap: n > 0 ? () => store.removeOne(deck, c) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$n/$max',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: DuelButton(
              label: 'เพิ่มเข้า "${deck.name}"',
              green: true,
              icon: Icons.add,
              onTap: () {
                final r = store.add(deck, c, max: max);
                showToast(context, addMessage(r, c));
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// หนึ่งหน้าของการ์ดหนึ่งใบ (รูป + ข้อมูล + คำแปลไทย + ข้อจำกัด)
class _CardPage extends StatefulWidget {
  const _CardPage({super.key, required this.card});
  final YgoCard card;

  @override
  State<_CardPage> createState() => _CardPageState();
}

class _CardPageState extends State<_CardPage> {
  late Future<String> _th;
  bool _showEn = false;

  @override
  void initState() {
    super.initState();
    _th = context.read<TranslationService>().translateCard(widget.card);
  }

  void _retry() {
    setState(() {
      _th = context
          .read<TranslationService>()
          .translateCard(widget.card, force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: AspectRatio(
              aspectRatio: 59 / 86,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: DL.cyan.withAlpha(90), blurRadius: 24),
                  ],
                ),
                child: Image.network(
                  c.imageUrl,
                  fit: BoxFit.contain,
                  webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                  loadingBuilder: (context, child, p) =>
                      p == null ? child : CardImage(url: c.imageSmall),
                  errorBuilder: (_, __, ___) => CardImage(url: c.imageSmall),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DuelPanel(
          borderColor: DL.cyan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: DL.gold),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: _chips(c)),
              if (c.isMonster) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (c.isLink)
                      _stat('LINK', '${c.linkval ?? '-'}')
                    else
                      _stat('ATK', statText(c.atk)),
                    const SizedBox(width: 24),
                    if (!c.isLink) _stat('DEF', statText(c.def)),
                    if (c.isLink) _stat('ATK', statText(c.atk)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        DuelPanel(child: _description(c)),
        const SizedBox(height: 14),
        _limitPanel(c),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _description(YgoCard c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(c.isNormal ? Icons.menu_book : Icons.auto_awesome,
                size: 18, color: DL.cyan),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _showEn
                    ? 'Original (English)'
                    : (c.isNormal ? 'คำบรรยาย' : 'ความสามารถ'),
                style: const TextStyle(
                    color: DL.cyan, fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            InkWell(
              onTap: () => setState(() => _showEn = !_showEn),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  _showEn ? 'ดูภาษาไทย' : 'ดูต้นฉบับ EN',
                  style: const TextStyle(
                      color: DL.muted,
                      fontSize: 12,
                      decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
        const Divider(color: DL.edge, height: 18),
        if (_showEn)
          SelectableText(c.desc,
              style: const TextStyle(height: 1.5, fontSize: 14))
        else
          FutureBuilder<String>(
            future: _th,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: DL.cyan),
                      ),
                      SizedBox(width: 10),
                      Text('กำลังแปลเป็นภาษาไทย...'),
                    ],
                  ),
                );
              }
              if (snap.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'แปลไม่สำเร็จ (ตรวจสอบอินเทอร์เน็ต) — แสดงต้นฉบับแทน',
                      style: TextStyle(color: DL.red, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(c.desc,
                        style: const TextStyle(height: 1.5, fontSize: 14)),
                    const SizedBox(height: 10),
                    DuelButton(
                      label: 'แปลอีกครั้ง',
                      icon: Icons.refresh,
                      dense: true,
                      onTap: _retry,
                    ),
                  ],
                );
              }
              return SelectableText(
                snap.data ?? '',
                style: const TextStyle(height: 1.6, fontSize: 15),
              );
            },
          ),
      ],
    );
  }

  /// ตั้งจำนวนใบสูงสุดของการ์ดใบนี้เอง (ตัวตรวจเด็คและปุ่มเพิ่มจะใช้ค่านี้)
  Widget _limitPanel(YgoCard c) {
    final limits = context.watch<LimitStore>();
    final cur = limits.maxFor(c.id);
    const opts = [
      (3, 'ปกติ (3)'),
      (2, '2 ใบ'),
      (1, '1 ใบ'),
      (0, 'ห้ามใช้'),
    ];
    return DuelPanel(
      borderColor: cur < 3 ? DL.gold : DL.edge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, size: 18, color: DL.gold),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('ข้อจำกัดจำนวนใบ (ตั้งเอง)',
                    style: TextStyle(
                        color: DL.gold,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'ข้อมูลรายการห้าม/จำกัดทางการของ Speed Duel และ Duel Links ไม่มีใน API '
            'ตั้งตามที่เกมแจ้งไว้ได้ ตัวตรวจเด็คและปุ่มเพิ่มการ์ดจะใช้ค่านี้',
            style: TextStyle(color: DL.muted, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in opts)
                _LimitChip(
                  label: o.$2,
                  selected: cur == o.$1,
                  danger: o.$1 == 0,
                  onTap: () => limits.set(c.id, o.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _chips(YgoCard c) {
    final out = <Widget>[_chip(FrameDot(frameColor(c)), c.type)];
    if (c.attribute != null) {
      out.add(_chip(AttributeBadge(c.attribute!, size: 18), c.attribute!));
    }
    if (c.race != null) out.add(_chip(null, c.race!));
    if (c.level != null && !c.isLink) {
      out.add(_chip(LevelBadge(size: 18, rank: c.isXyz),
          '${c.isXyz ? 'Rank' : 'Level'} ${c.level}'));
    }
    if (c.isLink && c.linkval != null) out.add(_chip(null, 'Link ${c.linkval}'));
    if (c.archetype != null) out.add(_chip(null, c.archetype!));
    if (c.inDl) out.add(_chip(null, 'Duel Links'));
    if (c.inSd) out.add(_chip(null, 'Speed Duel'));
    return out;
  }

  Widget _chip(Widget? leading, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: ShapeDecoration(
          shape: duelShape(cut: 6, color: DL.edge, width: 1.2),
          color: const Color(0xFF0C2766),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 6)],
            Text(t, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      );

  Widget _stat(String k, String v) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(k,
              style: const TextStyle(
                  color: DL.muted, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(v,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ],
      );
}

class _LimitChip extends StatelessWidget {
  const _LimitChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? DL.red : DL.cyan;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: duelShape(cut: 8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: ShapeDecoration(
            shape: duelShape(
              cut: 8,
              color: selected ? accent : DL.edge.withAlpha(190),
              width: selected ? 2.4 : 1.3,
            ),
            color: selected
                ? (danger ? const Color(0xFF8C1313) : const Color(0xFF1E6BE0))
                : const Color(0xFF0A2258),
            shadows: selected
                ? [BoxShadow(color: accent.withAlpha(130), blurRadius: 10)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_circle, size: 16, color: DL.gold),
                const SizedBox(width: 5),
              ],
              Text(label,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: selected ? Colors.white : DL.muted,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
