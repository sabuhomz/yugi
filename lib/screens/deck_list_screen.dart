import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/deck.dart';
import '../services/card_repository.dart';
import '../services/deck_store.dart';
import '../theme/duel_theme.dart';
import '../widgets/card_image.dart';
import '../widgets/dialogs.dart';
import 'deck_editor_screen.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key});

  Future<void> _create(BuildContext context) async {
    final store = context.read<DeckStore>();
    final name = await promptText(context,
        title: 'สร้างเด็คใหม่',
        hint: 'ชื่อเด็ค',
        initial: 'Deck ${store.decks.length + 1}',
        okLabel: 'สร้าง');
    if (name == null || !context.mounted) return;
    final d = store.create(name);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeckEditorScreen(deckId: d.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeckStore>();
    final repo = context.watch<CardRepository>();

    return Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const DuelTitleBar(title: 'My Decks', icon: Icons.inventory_2),
              Expanded(
                child: store.decks.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: Text(
                            'ยังไม่มีเด็ค\nกด "สร้างเด็คใหม่" เพื่อเริ่มจัดเด็ค Speed Duel',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: DL.muted, height: 1.6),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: store.decks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _DeckTile(deck: store.decks[i], repo: repo),
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(170),
                  border:
                      const Border(top: BorderSide(color: DL.edge, width: 2)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: DuelButton(
                    label: 'สร้างเด็คใหม่',
                    icon: Icons.add,
                    green: true,
                    onTap: () => _create(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({required this.deck, required this.repo});
  final Deck deck;
  final CardRepository repo;

  @override
  Widget build(BuildContext context) {
    final store = context.read<DeckStore>();
    final preview = deck.main.take(6).toList();
    return InkWell(
      customBorder: duelShape(cut: 12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DeckEditorScreen(deckId: deck.id)),
      ),
      child: DuelPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: DL.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: DL.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                ),
                PopupMenuButton<String>(
                  color: DL.panel,
                  icon: const Icon(Icons.more_vert, color: DL.muted),
                  onSelected: (v) async {
                    if (v == 'copy') {
                      store.duplicate(deck);
                    } else if (v == 'rename') {
                      final n = await promptText(context,
                          title: 'ตั้งชื่อเด็ค', initial: deck.name);
                      if (n != null) store.rename(deck, n);
                    } else if (v == 'delete') {
                      if (await confirm(context,
                          title: 'ลบเด็ค',
                          message: 'ลบ "${deck.name}" ถาวร?',
                          okLabel: 'ลบ')) {
                        store.delete(deck);
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('เปลี่ยนชื่อ')),
                    PopupMenuItem(value: 'copy', child: Text('ทำสำเนา')),
                    PopupMenuItem(value: 'delete', child: Text('ลบ')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Main ${deck.main.length}',
                    style: TextStyle(
                        color: deck.valid ? DL.text : DL.red,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 14),
                Text('Extra ${deck.extra.length}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (!deck.valid) ...[
                  const SizedBox(width: 10),
                  const Text('(ต้องมี 20–30 ใบ)',
                      style: TextStyle(color: DL.red, fontSize: 12)),
                ],
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final id in preview)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: AspectRatio(
                          aspectRatio: 59 / 86,
                          child: repo.byId[id] == null
                              ? const CardBack()
                              : CardImage(url: repo.byId[id]!.imageSmall),
                        ),
                      ),
                    ),
                  for (var i = preview.length; i < 6; i++)
                    const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
