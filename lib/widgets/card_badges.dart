import 'package:flutter/material.dart';

import '../models/card.dart';

/// สีตามกรอบการ์ดในเกม
Color frameColor(YgoCard c) {
  if (c.isSpell) return const Color(0xFF1D9E74);
  if (c.isTrap) return const Color(0xFFBC5A84);
  final t = c.type;
  if (t.contains('Fusion')) return const Color(0xFF8A4FBF);
  if (t.contains('Synchro')) return const Color(0xFFE8E8E8);
  if (t.contains('XYZ')) return const Color(0xFF222222);
  if (t.contains('Link')) return const Color(0xFF1B6FC2);
  if (t.contains('Ritual')) return const Color(0xFF3E7FD0);
  if (t.contains('Normal')) return const Color(0xFFE0B94A);
  return const Color(0xFFD9822B); // Effect
}

const _attr = <String, (Color, IconData)>{
  'DARK': (Color(0xFF6A3FA0), Icons.dark_mode),
  'LIGHT': (Color(0xFFE0B52A), Icons.wb_sunny),
  'EARTH': (Color(0xFF8C6A3A), Icons.landscape),
  'WATER': (Color(0xFF2B86D8), Icons.water_drop),
  'FIRE': (Color(0xFFD9442B), Icons.local_fire_department),
  'WIND': (Color(0xFF3FA66A), Icons.air),
  'DIVINE': (Color(0xFFC9A227), Icons.auto_awesome),
};

/// ไอคอนธาตุกลมๆ แบบในเกม
class AttributeBadge extends StatelessWidget {
  const AttributeBadge(this.attribute, {super.key, this.size = 22});
  final String attribute;
  final double size;

  @override
  Widget build(BuildContext context) {
    final a = _attr[attribute] ?? (const Color(0xFF666666), Icons.circle);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: a.$1,
        border: Border.all(color: Colors.white, width: 1.3),
      ),
      child: Icon(a.$2, size: size * 0.62, color: Colors.white),
    );
  }
}

/// ดาวเลเวล (แรงก์ของ Xyz เป็นดาวสีดำ)
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, this.size = 20, this.rank = false});
  final double size;
  final bool rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: rank ? const Color(0xFF222222) : const Color(0xFFE0872B),
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Icon(Icons.star, size: size * 0.65, color: Colors.white),
    );
  }
}

/// จุดสีบอกชนิดกรอบการ์ด
class FrameDot extends StatelessWidget {
  const FrameDot(this.color, {super.key});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.white70, width: 1),
        ),
      );
}
