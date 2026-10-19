import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/card_detail_screen.dart';
import '../services/card_repository.dart';
import '../services/deck_checker.dart';
import '../services/deck_store.dart';
import '../services/limit_store.dart';
import '../theme/duel_theme.dart';

Future<void> showDeckCheckSheet(BuildContext context, String deckId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DeckCheckSheet(deckId: deckId),
  );
}

class _DeckCheckSheet extends StatelessWidget {
  const _DeckCheckSheet({required this.deckId});
  final String deckId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<DeckStore>();
    final repo = context.watch<CardRepository>();
    final limits = context.watch<LimitStore>();
    final deck = store.byId(deckId);
    if (deck == null) return const SizedBox.shrink();

    final issues = checkDeck(deck, repo.byId, limits);
    final errors = errorCount(issues);
    final warns = warnCount(issues);

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: ShapeDecoration(
        shape: duelShape(cut: 18, width: 2),
        color: const Color(0xFF051540),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 18),
              Icon(
                errors > 0
                    ? Icons.cancel
                    : (warns > 0 ? Icons.warning_amber : Icons.check_circle),
                color: errors > 0
                    ? DL.red
                    : (warns > 0 ? DL.gold : DL.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errors > 0
                      ? 'พบข้อผิดพลาด $errors รายการ'
                      : (warns > 0 ? 'ผ่าน แต่มีข้อสังเกต $warns รายการ' : 'เด็คผ่านการตรวจ'),
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(color: DL.edge, height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: issues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _tile(context, repo, issues[i]),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 4, 16, 12 + MediaQuery.of(context).padding.bottom),
            child: const Text(
              'หมายเหตุ: YGOPRODeck ไม่มีรายการห้าม/จำกัดทางการของ Speed Duel และ '
              'Duel Links ตัวตรวจจึงใช้กฎโครงสร้าง (จำนวนใบ, ใบซ้ำ, เอ็กซ์ตร้าเด็ค) '
              'และข้อจำกัดที่คุณตั้งเองในหน้ารายละเอียดการ์ด',
              style: TextStyle(color: DL.muted, fontSize: 11.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, CardRepository repo, DeckIssue it) {
    final (IconData icon, Color color) = switch (it.severity) {
      Severity.error => (Icons.cancel, DL.red),
      Severity.warn => (Icons.warning_amber, DL.gold),
      Severity.ok => (Icons.check_circle, DL.green),
    };
    final card = it.cardId == null ? null : repo.byId[it.cardId];
    return InkWell(
      customBorder: duelShape(cut: 8),
      onTap: card == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CardDetailScreen(cards: [card])),
              ),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          shape: duelShape(cut: 8, color: color.withAlpha(200), width: 1.4),
          color: const Color(0xFF0A2258),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.title, style: const TextStyle(fontSize: 14.5)),
                  if (it.detail != null) ...[
                    const SizedBox(height: 3),
                    Text(it.detail!,
                        style: const TextStyle(color: DL.muted, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (card != null)
              const Icon(Icons.chevron_right, color: DL.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
