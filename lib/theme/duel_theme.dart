import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// สีและสไตล์หลักให้ใกล้เคียงหน้า Deck ของ Yu-Gi-Oh! Duel Links
class DL {
  static const bgTop = Color(0xFF020B26);
  static const bgMid = Color(0xFF0B3586);
  static const panel = Color(0xFF081B4B);
  static const panelLight = Color(0xFF0F3A8E);
  static const cyan = Color(0xFF47C8FF);
  static const edge = Color(0xFF2B6FD6);
  static const purple = Color(0xFFB36BE8);
  static const red = Color(0xFFE5393B);
  static const gold = Color(0xFFFFC83D);
  static const green = Color(0xFF4DB81F);
  static const text = Color(0xFFEAF4FF);
  static const muted = Color(0xFF9DB6E0);
}

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: DL.bgTop,
    colorScheme: const ColorScheme.dark(
      primary: DL.cyan,
      secondary: DL.gold,
      surface: DL.panel,
    ),
    textTheme: GoogleFonts.notoSansThaiTextTheme(base.textTheme)
        .apply(bodyColor: DL.text, displayColor: DL.text),
  );
}

/// กรอบมุมตัดแบบ Duel Links
ShapeBorder duelShape({
  double cut = 10,
  Color color = DL.cyan,
  double width = 1.5,
}) =>
    BeveledRectangleBorder(
      borderRadius: BorderRadius.circular(cut),
      side: BorderSide(color: color, width: width),
    );

class DuelBackground extends StatelessWidget {
  const DuelBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [DL.bgTop, DL.bgMid, Color(0xFF06194A), DL.bgTop],
          stops: [0, 0.35, 0.75, 1],
        ),
      ),
      child: CustomPaint(painter: _LinesPainter(), child: child),
    );
  }
}

class _LinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = DL.cyan.withAlpha(14)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
    final p2 = Paint()
      ..color = DL.cyan.withAlpha(10)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// แถบหัวข้อด้านบน เช่น "Deck"
class DuelTitleBar extends StatelessWidget {
  const DuelTitleBar({
    super.key,
    required this.title,
    this.icon = Icons.edit_note,
    this.onBack,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(150),
        border: const Border(bottom: BorderSide(color: DL.edge, width: 2)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: DL.text),
            ),
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(right: 10, left: 4),
            decoration: ShapeDecoration(
              shape: duelShape(cut: 6, color: DL.cyan, width: 1.2),
              color: DL.panelLight,
            ),
            child: Icon(icon, size: 20, color: DL.text),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// ปุ่มสไตล์ Duel Links (มุมตัด ไล่สีน้ำเงิน ขอบฟ้า)
class DuelButton extends StatelessWidget {
  const DuelButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.green = false,
    this.danger = false,
    this.dense = false,
    this.selected = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool green;
  final bool danger;
  final bool dense;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors;
    Color border = DL.cyan;
    if (green) {
      colors = const [Color(0xFF7BE03A), Color(0xFF2E8B10)];
      border = const Color(0xFFB8F58A);
    } else if (danger) {
      colors = const [Color(0xFFE5483F), Color(0xFF8C1313)];
      border = const Color(0xFFFFA39B);
    } else if (selected) {
      colors = const [Color(0xFF3FA2FF), Color(0xFF1250C8)];
    } else {
      colors = const [Color(0xFF1B58C9), Color(0xFF0A2A74)];
    }
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: duelShape(cut: 9),
          onTap: onTap,
          child: Ink(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 12 : 16,
              vertical: dense ? 8 : 12,
            ),
            decoration: ShapeDecoration(
              shape: duelShape(cut: 9, color: border),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: dense ? 16 : 20, color: DL.text),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: dense ? 13 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// กล่องข้อความ/พาเนลสไตล์ Duel Links
class DuelPanel extends StatelessWidget {
  const DuelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderColor = DL.edge,
    this.cut = 12,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color borderColor;
  final double cut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        shape: duelShape(cut: cut, color: borderColor, width: 1.6),
        color: DL.panel.withAlpha(235),
      ),
      child: child,
    );
  }
}

/// วงกลมใส่เลขของช่องการ์ด
class SlotNumber extends StatelessWidget {
  const SlotNumber(this.n, {super.key, this.red = false});
  final int n;
  final bool red;

  @override
  Widget build(BuildContext context) {
    final c = red ? DL.red : DL.cyan;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF031038),
        border: Border.all(color: c, width: 1.6),
      ),
      child: Text(
        '$n',
        style: TextStyle(
          color: c,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

void showToast(BuildContext context, String msg) {
  final m = ScaffoldMessenger.of(context);
  m.clearSnackBars();
  m.showSnackBar(
    SnackBar(
      content: Text(msg),
      duration: const Duration(milliseconds: 1400),
      behavior: SnackBarBehavior.floating,
      backgroundColor: DL.panelLight,
      shape: duelShape(cut: 8),
    ),
  );
}
