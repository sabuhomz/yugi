import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/duel_theme.dart';

class _OnbPage {
  const _OnbPage(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _OnbPage(
    Icons.style,
    'ยินดีต้อนรับสู่ Speed Duel Cards',
    'คลังการ์ด Yu-Gi-Oh! Duel Links แบบ Speed Duel พร้อมรูปการ์ดจริง '
        'อัปเดตข้อมูลตามฐานข้อมูล YGOPRODeck',
  ),
  _OnbPage(
    Icons.translate,
    'ความสามารถเป็นภาษาไทย',
    'ชื่อการ์ดเป็นภาษาอังกฤษเหมือนเดิม ส่วนความสามารถแปลเป็นไทยให้ '
        'ค้นหาตามชื่อและกรองตามประเภท ธาตุ เลเวล ได้',
  ),
  _OnbPage(
    Icons.inventory_2,
    'จัดเด็คของคุณเอง',
    'Main Deck 20–30 ใบ และ Extra Deck 9 ใบ ตรวจเด็ค '
        'และจำลองการจั่วเพื่อดูโอกาสเปิดมือแรก',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  bool get _last => _i == _pages.length - 1;

  void _next() {
    if (_last) {
      widget.onDone();
    } else {
      _pc.nextPage(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                      child: TextButton(
                        onPressed: _last ? null : widget.onDone,
                        child: Text('ข้าม',
                            style: TextStyle(
                                color: _last ? Colors.transparent : DL.muted)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: PageView.builder(
                        controller: _pc,
                        itemCount: _pages.length,
                        onPageChanged: (i) => setState(() => _i = i),
                        itemBuilder: (_, i) => _page(_pages[i]),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: i == _i ? DL.cyan : DL.edge,
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
                    child: SizedBox(
                      width: double.infinity,
                      child: DuelButton(
                        label: _last ? 'เริ่มต้นใช้งาน' : 'ถัดไป',
                        icon: _last ? Icons.login : Icons.arrow_forward,
                        green: _last,
                        onTap: _next,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _page(_OnbPage p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: ShapeDecoration(
              shape: duelShape(cut: 26, color: DL.cyan, width: 2.4),
              color: DL.panelLight,
              shadows: [BoxShadow(color: DL.cyan.withAlpha(110), blurRadius: 30)],
            ),
            child: Icon(p.icon, size: 76, color: DL.text),
          ),
          const SizedBox(height: 34),
          Text(
            p.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: DL.gold),
          ),
          const SizedBox(height: 14),
          Text(
            p.body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15.5, height: 1.6, color: DL.muted),
          ),
        ],
      ),
    );
  }
}
