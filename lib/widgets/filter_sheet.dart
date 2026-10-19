import 'package:flutter/material.dart';

import '../models/card_filter.dart';
import '../theme/duel_theme.dart';

/// เปิดหน้าต่างฟิลเตอร์ คืนค่า filter ใหม่ (หรือ null ถ้าปิดโดยไม่กดใช้)
Future<CardFilter?> showFilterSheet(
  BuildContext context,
  CardFilter current,
  List<String> races,
) {
  return showModalBottomSheet<CardFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterSheet(initial: current.copy(), races: races),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial, required this.races});
  final CardFilter initial;
  final List<String> races;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late CardFilter f = widget.initial;

  void _toggle<T>(Set<T> s, T v) {
    setState(() => s.contains(v) ? s.remove(v) : s.add(v));
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.86;
    return Container(
      height: h,
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
              const Icon(Icons.filter_alt, color: DL.cyan),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('ฟิลเตอร์ / เรียงลำดับ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(color: DL.edge, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('เรียงตาม'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final k in SortKey.values)
                    _OptChip(
                      label: sortLabels[k]!,
                      selected: f.sort == k,
                      onTap: () => setState(() => f.sort = k),
                    ),
                  _OptChip(
                    label: f.asc ? 'น้อย → มาก / A-Z' : 'มาก → น้อย / Z-A',
                    selected: true,
                    icon: Icons.swap_vert,
                    onTap: () => setState(() => f.asc = !f.asc),
                  ),
                ]),
                _section('แหล่งที่มาของการ์ด'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in srcLabels.entries)
                    _OptChip(
                      label: e.value,
                      selected: f.srcs.contains(e.key),
                      onTap: () => _toggle(f.srcs, e.key),
                    ),
                ]),
                _section('ประเภทการ์ด'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final e in catLabels.entries)
                    _OptChip(
                      label: e.value,
                      selected: f.cats.contains(e.key),
                      onTap: () => _toggle(f.cats, e.key),
                    ),
                ]),
                _section('ชนิดมอนสเตอร์'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in subTypes)
                    _OptChip(
                      label: s,
                      selected: f.subs.contains(s),
                      onTap: () => _toggle(f.subs, s),
                    ),
                ]),
                _section('ธาตุ (Attribute)'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final a in attributes)
                    _OptChip(
                      label: a,
                      selected: f.attrs.contains(a),
                      onTap: () => _toggle(f.attrs, a),
                    ),
                ]),
                _section('เลเวล / แรงก์'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 1; i <= 12; i++)
                    _OptChip(
                      label: '★$i',
                      selected: f.levels.contains(i),
                      onTap: () => _toggle(f.levels, i),
                    ),
                ]),
                _section('เผ่า / ชนิด (Type)'),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final r in widget.races)
                    _OptChip(
                      label: r,
                      selected: f.races.contains(r),
                      onTap: () => _toggle(f.races, r),
                    ),
                ]),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 10, 16, 12 + MediaQuery.of(context).padding.bottom),
            child: Row(
              children: [
                Expanded(
                  child: DuelButton(
                    label: 'ล้างตัวกรอง',
                    onTap: () => setState(() => f.clear()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DuelButton(
                    label: 'ใช้ตัวกรอง',
                    green: true,
                    icon: Icons.check,
                    onTap: () => Navigator.pop(context, f),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(t,
            style: const TextStyle(
                color: DL.gold, fontWeight: FontWeight.w600, fontSize: 15)),
      );
}

class _OptChip extends StatelessWidget {
  const _OptChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: duelShape(cut: 8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: ShapeDecoration(
            shape: duelShape(
              cut: 8,
              color: selected ? DL.cyan : DL.edge.withAlpha(190),
              width: selected ? 2.4 : 1.3,
            ),
            color: selected ? const Color(0xFF1E6BE0) : const Color(0xFF0A2258),
            shadows: selected
                ? [BoxShadow(color: DL.cyan.withAlpha(130), blurRadius: 10)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check_circle, size: 16, color: DL.gold),
                const SizedBox(width: 5),
              ] else if (icon != null) ...[
                Icon(icon, size: 15),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  color: selected ? Colors.white : DL.muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
