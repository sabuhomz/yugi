import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/deck_store.dart';
import '../theme/duel_theme.dart';
import '../widgets/dialogs.dart';

/// แท็บโปรไฟล์: ข้อมูลบัญชี + ออกจากระบบ
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _method(User u) {
    final ids = u.providerData.map((p) => p.providerId).toSet();
    if (ids.contains('google.com')) return 'Google';
    if (ids.contains('password')) return 'อีเมลและรหัสผ่าน';
    return ids.isEmpty ? '-' : ids.join(', ');
  }

  Future<void> _logout(BuildContext context, AuthService auth) async {
    final ok = await confirm(
      context,
      title: 'ออกจากระบบ',
      message: 'ต้องการออกจากระบบใช่ไหม?',
      okLabel: 'ออกจากระบบ',
    );
    if (ok) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final decks = context.watch<DeckStore>().decks.length;

    return Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const DuelTitleBar(title: 'Profile', icon: Icons.person),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    if (!auth.available)
                      const DuelPanel(
                        borderColor: DL.gold,
                        child: Text(
                          'กำลังใช้งานโดยไม่ล็อกอิน (ยังไม่ได้ตั้งค่า Firebase) '
                          'ดูขั้นตอนตั้งค่าใน README.md',
                          style: TextStyle(color: DL.muted, height: 1.5),
                        ),
                      )
                    else
                      StreamBuilder<User?>(
                        stream: auth.changes,
                        initialData: auth.user,
                        builder: (context, snap) {
                          final u = snap.data;
                          if (u == null) return const SizedBox.shrink();
                          return _account(context, auth, u);
                        },
                      ),
                    const SizedBox(height: 14),
                    DuelPanel(
                      child: Text(
                        'เด็คที่สร้างไว้ ($decks เด็ค) เก็บในเครื่องนี้เท่านั้น '
                        'ยังไม่ผูกกับบัญชี',
                        style: const TextStyle(color: DL.muted, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _account(BuildContext context, AuthService auth, User u) {
    final name = (u.displayName ?? '').trim();
    final base = name.isNotEmpty ? name : (u.email ?? '');
    final initial = base.isEmpty ? '?' : base.substring(0, 1).toUpperCase();
    final fallback = Center(
      child: Text(initial,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
    );
    return DuelPanel(
      borderColor: DL.cyan,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DL.panelLight,
              border: Border.all(color: DL.cyan, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: u.photoURL == null
                ? fallback
                : Image.network(
                    u.photoURL!,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (_, __, ___) => fallback,
                  ),
          ),
          const SizedBox(height: 12),
          Text(name.isEmpty ? 'ผู้เล่น' : name,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: DL.gold)),
          const SizedBox(height: 2),
          Text(u.email ?? '-', style: const TextStyle(color: DL.muted)),
          const SizedBox(height: 6),
          Text('เข้าสู่ระบบด้วย ${_method(u)}',
              style: const TextStyle(color: DL.muted, fontSize: 12.5)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: DuelButton(
              label: 'ออกจากระบบ',
              icon: Icons.logout,
              danger: true,
              onTap: () => _logout(context, auth),
            ),
          ),
        ],
      ),
    );
  }
}
