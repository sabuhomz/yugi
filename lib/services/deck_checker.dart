import '../models/card.dart';
import '../models/deck.dart';
import 'deck_store.dart';
import 'limit_store.dart';

enum Severity { error, warn, ok }

class DeckIssue {
  const DeckIssue(this.severity, this.title, {this.detail, this.cardId});
  final Severity severity;
  final String title;
  final String? detail;
  final int? cardId;
}

/// ตรวจเด็คตามกฎโครงสร้าง + ข้อจำกัดที่ผู้ใช้ตั้งเอง
List<DeckIssue> checkDeck(
  Deck d,
  Map<int, YgoCard> byId,
  LimitStore limits,
) {
  final out = <DeckIssue>[];

  // 1) จำนวนใบ
  if (d.main.length < mainMin) {
    out.add(DeckIssue(
      Severity.error,
      'เด็คหลักมี ${d.main.length} ใบ ต้องมีอย่างน้อย $mainMin',
      detail: 'ขาดอีก ${mainMin - d.main.length} ใบ',
    ));
  } else if (d.main.length > mainMax) {
    out.add(DeckIssue(
      Severity.error,
      'เด็คหลักมี ${d.main.length} ใบ เกิน $mainMax',
      detail: 'ต้องนำออก ${d.main.length - mainMax} ใบ',
    ));
  }
  if (d.extra.length > extraMax) {
    out.add(DeckIssue(
      Severity.error,
      'เอ็กซ์ตร้าเด็คมี ${d.extra.length} ใบ เกิน $extraMax',
    ));
  }

  // 2) จำนวนสำเนาต่อการ์ด
  final counts = <int, int>{};
  for (final id in [...d.main, ...d.extra]) {
    counts[id] = (counts[id] ?? 0) + 1;
  }
  counts.forEach((id, n) {
    final c = byId[id];
    final name = c?.name ?? 'การ์ด #$id';
    if (n > copyMax) {
      out.add(DeckIssue(
        Severity.error,
        '$name ใส่เกิน $copyMax ใบ (มี $n)',
        cardId: id,
      ));
    }
    final lim = limits.maxFor(id);
    if (lim < copyMax && n > lim) {
      out.add(DeckIssue(
        Severity.error,
        lim == 0
            ? '$name ถูกตั้งเป็นห้ามใช้'
            : '$name ถูกจำกัดที่ $lim ใบ (มี $n)',
        detail: 'ตามข้อจำกัดที่ตั้งเองในหน้ารายละเอียดการ์ด',
        cardId: id,
      ));
    }
  });

  // 3) การ์ดที่ไม่พบในฐานข้อมูล / อยู่ผิดเด็ค
  final missing = counts.keys.where((id) => byId[id] == null).length;
  if (missing > 0) {
    out.add(DeckIssue(
      Severity.warn,
      'มี $missing รายการที่ไม่พบในฐานข้อมูลปัจจุบัน',
      detail: 'อาจถูกลบหรือเปลี่ยนรหัสหลังอัปเดต ลองกดรีเฟรชข้อมูลการ์ด',
    ));
  }
  for (final id in d.main.toSet()) {
    final c = byId[id];
    if (c != null && c.isExtra) {
      out.add(DeckIssue(
        Severity.error,
        '${c.name} เป็นการ์ดเอ็กซ์ตร้าเด็ค แต่อยู่ในเด็คหลัก',
        cardId: id,
      ));
    }
  }
  for (final id in d.extra.toSet()) {
    final c = byId[id];
    if (c != null && !c.isExtra) {
      out.add(DeckIssue(
        Severity.error,
        '${c.name} ไม่ใช่การ์ดเอ็กซ์ตร้าเด็ค แต่อยู่ในช่อง Extra',
        cardId: id,
      ));
    }
  }

  // 4) ข้อสังเกต (ไม่ใช่กฎ)
  if (d.main.isNotEmpty) {
    final monsters = d.main.where((id) => byId[id]?.isMonster ?? false).length;
    if (monsters == 0) {
      out.add(const DeckIssue(
        Severity.warn,
        'เด็คหลักไม่มีมอนสเตอร์เลย',
        detail: 'เป็นข้อสังเกต ไม่ใช่การผิดกฎ',
      ));
    }
  }

  if (out.isEmpty) {
    out.add(const DeckIssue(Severity.ok, 'เด็คผ่านทุกข้อที่ตรวจ'));
  }
  // error ก่อน, warn, ok
  out.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return out;
}

int errorCount(List<DeckIssue> l) =>
    l.where((e) => e.severity == Severity.error).length;
int warnCount(List<DeckIssue> l) =>
    l.where((e) => e.severity == Severity.warn).length;
