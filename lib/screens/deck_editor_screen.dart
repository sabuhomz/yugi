import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/deck.dart';
import '../services/card_repository.dart';
import '../services/deck_checker.dart';
import '../services/deck_store.dart';
import '../services/limit_store.dart';
import '../theme/duel_theme.dart';
import '../widgets/card_badges.dart';
import '../widgets/card_image.dart';
import '../widgets/deck_check_sheet.dart';
import '../widgets/dialogs.dart';
import 'card_detail_screen.dart';
import 'cards_screen.dart';
import 'draw_sim_screen.dart';

/// หน้าจัดเด็ค: Main 20–30 ใบ + Extra สูงสุด 9 ใบ
class DeckEditorScreen extends StatelessWidget {
  const DeckEditorScreen({super.key, required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeckStore>();
    final repo = context.watch<CardRepository>();
    final deck = store.byId(deckId);
    if (deck == null) {
      return const Scaffold(body: Center(child: Text('ไม่พบเด็คนี้')));
    }

    final limits = context.watch<LimitStore>();
    final errs = errorCount(checkDeck(deck, repo.byId, limits));
    final mainOk = deck.main.length >= mainMin;

    return Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: SafeArea(
          child: Column(
            children: [
              DuelTitleBar(
                title: 'Deck',
                icon: Icons.edit_note,
                onBack: () => Navigator.pop(context),
                trailing: _menu(context, store, repo, deck),
              ),
              // สรุปจำนวน + ชื่อเด็ค
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _count(Icons.style, 'Main Deck', deck.main.length,
                              mainOk ? DL.text : DL.red),
                          const SizedBox(height: 4),
                          _count(Icons.auto_awesome_motion, 'Extra Deck',
                              deck.extra.length, DL.text),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: InkWell(
                        customBorder: duelShape(cut: 9),
                        onTap: () => _rename(context, store, deck),
                        child: Ink(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: ShapeDecoration(
                            shape: duelShape(cut: 9, color: DL.cyan),
                            color: const Color(0xFF0A2258),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.stars, color: DL.gold, size: 20),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  deck.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: DL.gold,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(Icons.edit, size: 16, color: DL.muted),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!mainOk)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'เด็คหลักต้องมีอย่างน้อย $mainMin ใบ (ขาดอีก ${mainMin - deck.main.length})',
                    style: const TextStyle(color: DL.red, fontSize: 12),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: DuelButton(
                              label: errs > 0 ? 'ตรวจเด็ค ($errs)' : 'ตรวจเด็ค',
                              icon: errs > 0
                                  ? Icons.error_outline
                                  : Icons.fact_check,
                              danger: errs > 0,
                              dense: true,
                              onTap: () => showDeckCheckSheet(context, deck.id),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DuelButton(
                              label: 'จำลองการจั่ว',
                              icon: Icons.casino,
                              dense: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DrawSimScreen(deckId: deck.id),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _label('Main Deck  ($mainMin–$mainMax)', DL.cyan),
                    _grid(context, repo, deck, extra: false),
                    const SizedBox(height: 14),
                    _label('Extra Deck  (สูงสุด $extraMax)', DL.purple),
                    _grid(context, repo, deck, extra: true),
                  ],
                ),
              ),
              _bottomBar(context, store, deck),
            ],
          ),
        ),
      ),
    );
  }

  Widget _count(IconData i, String label, int n, Color c) => Row(
        children: [
          Icon(i, size: 18, color: DL.gold),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text('$n',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(width: 12),
        ],
      );

  Widget _label(String t, Color c) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Row(
          children: [
            Container(width: 4, height: 16, color: c),
            const SizedBox(width: 8),
            Text(t,
                style: TextStyle(
                    color: c, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _grid(BuildContext context, CardRepository repo, Deck deck,
      {required bool extra}) {
    final ids = extra ? deck.extra : deck.main;
    final total = extra ? extraMax : mainMax;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 59 / 86,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
      ),
      itemCount: total,
      itemBuilder: (_, i) {
        final YgoCard? card = i < ids.length ? repo.byId[ids[i]] : null;
        final filled = i < ids.length;
        return _Slot(
          number: i + 1,
          extra: extra,
          filled: filled,
          card: card,
          onTap: () {
            if (filled && card != null) {
              _cardSheet(context, deck, card, extra, i);
            } else if (!filled) {
              _openPicker(context, deck, extra);
            }
          },
        );
      },
    );
  }

  void _openPicker(BuildContext context, Deck deck, bool extra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardsScreen(deckId: deck.id, initialExtra: extra),
      ),
    );
  }

  void _cardSheet(
      BuildContext context, Deck deck, YgoCard c, bool extra, int index) {
    final store = context.read<DeckStore>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(ctx).padding.bottom),
        decoration: ShapeDecoration(
          shape: duelShape(cut: 16, width: 2),
          color: const Color(0xFF051540),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 93,
                  child: CardImage(url: c.imageSmall),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              color: DL.gold,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(c.type,
                          style:
                              const TextStyle(color: DL.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DuelButton(
                    label: 'รายละเอียด',
                    icon: Icons.info_outline,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CardDetailScreen(cards: [c])),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DuelButton(
                    label: 'นำออก',
                    icon: Icons.delete_outline,
                    danger: true,
                    onTap: () {
                      store.removeAt(deck, extra, index);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context, DeckStore store, Deck deck) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          10, 10, 10, 10 + MediaQuery.of(context).padding.bottom * 0),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        border: const Border(top: BorderSide(color: DL.edge, width: 2)),
      ),
      child: Row(
        children: [
          DuelButton(
            label: '',
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: DuelButton(
              label: 'Add Cards',
              icon: Icons.add,
              green: true,
              onTap: () => _openPicker(context, deck, false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DuelButton(
              label: 'Copy Deck',
              icon: Icons.copy,
              onTap: () {
                store.duplicate(deck);
                showToast(context, 'ทำสำเนาเด็คแล้ว');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, DeckStore store, CardRepository repo,
      Deck deck) {
    return PopupMenuButton<String>(
      color: DL.panel,
      shape: duelShape(cut: 10),
      onSelected: (v) async {
        switch (v) {
          case 'rename':
            _rename(context, store, deck);
          case 'sort':
            store.sortDeck(deck, repo.byId);
          case 'clear':
            if (await confirm(context,
                title: 'ล้างเด็ค',
                message: 'นำการ์ดทั้งหมดออกจากเด็คนี้?',
                okLabel: 'ล้าง')) {
              store.clear(deck);
            }
          case 'delete':
            if (await confirm(context,
                title: 'ลบเด็ค',
                message: 'ลบ "${deck.name}" ถาวร?',
                okLabel: 'ลบ')) {
              store.delete(deck);
              if (context.mounted) Navigator.pop(context);
            }
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'rename', child: Text('เปลี่ยนชื่อเด็ค')),
        PopupMenuItem(value: 'sort', child: Text('เรียงการ์ดอัตโนมัติ')),
        PopupMenuItem(value: 'clear', child: Text('ล้างเด็ค')),
        PopupMenuItem(value: 'delete', child: Text('ลบเด็ค')),
      ],
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          shape: duelShape(cut: 8, color: DL.cyan),
          color: const Color(0xFF0F3A8E),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu, size: 18),
            SizedBox(width: 6),
            Text('MENU', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, DeckStore store, Deck deck) async {
    final n = await promptText(context,
        title: 'ตั้งชื่อเด็ค', initial: deck.name, hint: 'ชื่อเด็ค');
    if (n != null) store.rename(deck, n);
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.number,
    required this.extra,
    required this.filled,
    required this.card,
    required this.onTap,
  });

  final int number;
  final bool extra;
  final bool filled;
  final YgoCard? card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = extra ? DL.purple : DL.cyan;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
              color: border.withAlpha(filled ? 255 : 150), width: filled ? 1.5 : 1.2),
          color: filled ? Colors.black : const Color(0xFF07204F).withAlpha(200),
        ),
        child: filled
            ? Stack(
                fit: StackFit.expand,
                children: [
                  card == null
                      ? const CardBack()
                      : CardImage(url: card!.imageSmall, fit: BoxFit.fill),
                  if (card != null && card!.level != null && !card!.isLink)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        color: Colors.black.withAlpha(170),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LevelBadge(size: 11, rank: card!.isXyz),
                            const SizedBox(width: 2),
                            Text('${card!.level}',
                                style: const TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            : Center(child: SlotNumber(number, red: extra)),
      ),
    );
  }
}
