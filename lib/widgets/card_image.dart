import 'package:flutter/material.dart';

import '../theme/duel_theme.dart';

/// รูปการ์ดจริงจาก YGOPRODeck (แคชลงเครื่องอัตโนมัติ)
class CardImage extends StatelessWidget {
  const CardImage({super.key, required this.url, this.fit = BoxFit.contain});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      gaplessPlayback: true,
      // บนเว็บ: ถ้าเซิร์ฟเวอร์รูปไม่ส่ง CORS ให้ใช้ <img> ของเบราว์เซอร์แทน
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const CardBack(),
      errorBuilder: (_, e, __) {
        debugPrint('โหลดรูปไม่สำเร็จ: $url -> $e');
        return const CardBack(error: true);
      },
    );
  }
}

class CardBack extends StatelessWidget {
  const CardBack({super.key, this.error = false});
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B3A1A), Color(0xFF2A1408)],
        ),
        border: Border.all(color: const Color(0xFFB07A3A)),
      ),
      child: Center(
        child: Icon(
          error ? Icons.broken_image_outlined : Icons.style,
          color: DL.gold.withAlpha(150),
          size: 20,
        ),
      ),
    );
  }
}
