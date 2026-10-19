import 'package:flutter/material.dart';

import '../theme/duel_theme.dart';

/// แสดงเมื่อ Firebase ยังไม่ถูกตั้งค่า (ยังไม่ได้รัน flutterfire configure)
class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    const steps = [
      'สร้างโปรเจกต์ที่ console.firebase.google.com',
      'เปิด Authentication แล้วเปิดวิธี Email/Password และ Google',
      'รัน  dart pub global activate flutterfire_cli',
      'รัน  flutterfire configure  ในโฟลเดอร์โปรเจกต์ แล้วรันแอปใหม่',
    ];
    return Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: DuelPanel(
                  borderColor: DL.gold,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.build_circle, color: DL.gold),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('ยังไม่ได้ตั้งค่า Firebase',
                                style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: DL.gold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'ระบบล็อกอินต้องใช้โปรเจกต์ Firebase ของคุณ ทำตามนี้ (รายละเอียดใน README.md):',
                        style: TextStyle(color: DL.muted, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SlotNumber(i + 1),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(steps[i],
                                    style: const TextStyle(height: 1.4)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      DuelButton(
                        label: 'ใช้งานโดยไม่ล็อกอินไปก่อน',
                        icon: Icons.arrow_forward,
                        onTap: onContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
