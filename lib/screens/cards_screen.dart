import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card.dart';
import '../models/card_filter.dart';
import '../models/deck.dart';
import '../services/card_repository.dart';
import '../services/deck_store.dart';
import '../services/limit_store.dart';
import '../theme/duel_theme.dart';
import '../widgets/card_image.dart';
import '../widgets/filter_sheet.dart';
import 'card_detail_screen.dart';

/// หน้าคลังการ์ด (แท็บหลัก) หรือหน้าเลือกการ์ดเข้าเด็ค (เมื่อมี deckId)
class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key, this.deckId, this.initialExtra = false});

  final String? deckId;
  final bool initialExtra;

  bool get pick => deckId != null;

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final _search = TextEditingController();
  late CardFilter _f;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _f = CardFilter();
    if (widget.pick) {
      _f.cats = widget.initialExtra ? {'extra'} : {'monster', 'spell', 'trap'};
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openFilter(CardRepository repo) async {
    final r = await showFilterSheet(context, _f, repo.races);
    if (r != null) setState(() => _f = r);
  }

  void _quickAdd(Deck deck, YgoCard c) {
    final store = context.read<DeckStore>();
    final max = context.read<LimitStore>().maxFor(c.id);
    final r = store.add(deck, c, max: max);
    showToast(context, addMessage(r, c));
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<CardRepository>();
    final store = context.watch<DeckStore>();
    final deck = widget.deckId == null ? null : store.byId(widget.deckId!);
    final ready = !repo.loading && repo.error == null;
    final list = ready ? _f.apply(repo.cards, _q) : <YgoCard>[];

    return Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              DuelTitleBar(
                title: widget.pick ? 'Add Cards' : 'Speed Duel Cards',
                icon: widget.pick ? Icons.add_card : Icons.style,
                onBack: widget.pick ? () => Navigator.pop(context) : null,
                trailing: deck == null
                    ? IconButton(
                        tooltip: 'อัปเดตข้อมูลการ์ด',
                        icon: const Icon(Icons.refresh, color: DL.cyan),
                        onPressed: repo.loading
                            ? null
                            : () => repo.load(force: true),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'Main ${deck.main.length}/$mainMax  Extra ${deck.extra.length}/$extraMax',
                          style: const TextStyle(
                              color: DL.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: DL.panel.withAlpha(230),
                    hintText: 'ค้นหาชื่อการ์ด (ภาษาอังกฤษ)',
                    hintStyle: const TextStyle(color: DL.muted),
                    prefixIcon: const Icon(Icons.search, color: DL.cyan),
                    suffixIcon: _q.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() => _q = '');
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: DL.edge),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: DL.edge, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: DL.cyan, width: 1.8),
                    ),
                  ),
                ),
              ),
              if (ready)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'พบ ${list.length} ใบ  ·  DL ${repo.dlCount} / SD ${repo.sdCount}',
                        style: const TextStyle(color: DL.muted, fontSize: 12)),
                  ),
                ),
              Expanded(child: _body(repo, deck, list)),
              _bottomBar(repo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(CardRepository repo, Deck? deck, List<YgoCard> list) {
    if (repo.loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: DL.cyan),
            SizedBox(height: 14),
            Text('กำลังโหลดการ์ด Speed Duel...'),
          ],
        ),
      );
    }
    if (repo.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 40, color: DL.muted),
              const SizedBox(height: 10),
              Text('โหลดข้อมูลไม่สำเร็จ\n${repo.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: DL.muted)),
              const SizedBox(height: 14),
              DuelButton(
                label: 'ลองอีกครั้ง',
                icon: Icons.refresh,
                onTap: () => repo.load(force: true),
              ),
            ],
          ),
        ),
      );
    }
    if (list.isEmpty) {
      return const Center(
        child: Text('ไม่พบการ์ดที่ตรงเงื่อนไข', style: TextStyle(color: DL.muted)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.54,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final c = list[i];
        return _CardTile(
          card: c,
          copies: deck?.count(c.id) ?? 0,
          pick: widget.pick,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CardDetailScreen(
                  cards: list, index: i, deckId: widget.deckId),
            ),
          ),
          onAdd: deck == null ? null : () => _quickAdd(deck, c),
        );
      },
    );
  }

  Widget _bottomBar(CardRepository repo) {
    final dir = _f.sort == SortKey.name
        ? (_f.asc ? 'A-Z' : 'Z-A')
        : (_f.asc ? 'น้อย→มาก' : 'มาก→น้อย');
    return Container(
      padding: EdgeInsets.fromLTRB(
          10, 8, 10, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(170),
        border: const Border(top: BorderSide(color: DL.edge, width: 2)),
      ),
      child: Row(
        children: [
          InkWell(
            customBorder: duelShape(cut: 8),
            onTap: repo.loading || repo.error != null ? null : () => _openFilter(repo),
            child: Ink(
              width: 52,
              height: 46,
              decoration: ShapeDecoration(
                shape: duelShape(cut: 8, color: DL.cyan),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1B58C9), Color(0xFF0A2A74)],
                ),
              ),
              child: const Icon(Icons.arrow_drop_down, size: 36),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sort: ${sortLabels[_f.sort]} ($dir)\nFilter: ${_f.active ? 'On' : 'Off'}',
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
          if (_f.active)
            DuelButton(
              label: 'ล้าง',
              dense: true,
              onTap: () => setState(() => _f.clear()),
            ),
        ],
      ),
    );
  }
}


class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.copies,
    required this.pick,
    required this.onTap,
    this.onAdd,
  });

  final YgoCard card;
  final int copies;
  final bool pick;
  final VoidCallback onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: CardImage(url: card.imageSmall)),
                if (copies > 0)
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: DL.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Text('x$copies',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (pick && onAdd != null)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: InkWell(
                      onTap: onAdd,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DL.green,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.add, size: 22),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 30,
            child: Text(
              card.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}
