import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/deck.dart';
import '../services/deck_store.dart';
import '../services/translation_service.dart';
import '../theme/duel_theme.dart';
import '../widgets/card_badges.dart';
import '../widgets/card_image.dart';

class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.card, this.deckId});

  final YgoCard card;
  final String? deckId;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
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
    final store = context.watch<DeckStore>();
    final deck = widget.deckId == null ? null : store.byId(widget.deckId!);

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
              ),
              Expanded(
                child: ListView(
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
                                BoxShadow(
                                    color: DL.cyan.withAlpha(90), blurRadius: 24),
                              ],
                            ),
                            child: Image.network(
                              c.imageUrl,
                              fit: BoxFit.contain,
                              webHtmlElementStrategy:
                                  WebHtmlElementStrategy.prefer,
                              loadingBuilder: (context, child, p) => p == null
                                  ? child
                                  : CardImage(url: c.imageSmall),
                              errorBuilder: (_, __, ___) =>
                                  CardImage(url: c.imageSmall),
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
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: DL.gold),
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
                    DuelPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                  c.isNormal
                                      ? Icons.menu_book
                                      : Icons.auto_awesome,
                                  size: 18,
                                  color: DL.cyan),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _showEn
                                      ? 'Original (English)'
                                      : (c.isNormal ? 'คำบรรยาย' : 'ความสามารถ'),
                                  style: const TextStyle(
                                      color: DL.cyan,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
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
                                if (snap.connectionState !=
                                    ConnectionState.done) {
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
                                        style: TextStyle(
                                            color: DL.red, fontSize: 12),
                                      ),
                                      const SizedBox(height: 8),
                                      SelectableText(c.desc,
                                          style: const TextStyle(
                                              height: 1.5, fontSize: 14)),
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
                      ),
                    ),
                    if (deck != null) const SizedBox(height: 90),
                  ],
                ),
              ),
              if (deck != null) _deckBar(context, deck, c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deckBar(BuildContext context, Deck deck, YgoCard c) {
    final store = context.read<DeckStore>();
    final n = deck.count(c.id);
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).padding.bottom * 0),
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
            child: Text('$n/$copyMax',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: DuelButton(
              label: 'เพิ่มเข้า "${deck.name}"',
              green: true,
              icon: Icons.add,
              onTap: () {
                final r = store.add(deck, c);
                showToast(context, addMessage(r, c));
              },
            ),
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
