import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/onboarding_store.dart';
import '../theme/duel_theme.dart';
import 'auth_screen.dart';
import 'firebase_setup_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// ลำดับหน้า: onboarding (ครั้งแรก) → เข้าสู่ระบบ/สมัคร → หน้าหลัก
/// ออกจากระบบแล้วจะกลับมาหน้าเข้าสู่ระบบเองอัตโนมัติ
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _onboarded;
  bool _guest = false;

  @override
  void initState() {
    super.initState();
    OnboardingStore.isDone().then((v) {
      if (mounted) setState(() => _onboarded = v);
    });
  }

  Future<void> _finishOnboarding() async {
    await OnboardingStore.markDone();
    if (mounted) setState(() => _onboarded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_onboarded == null) return const _Splash();
    if (_onboarded == false) {
      return OnboardingScreen(onDone: _finishOnboarding);
    }

    final auth = context.read<AuthService>();
    if (!auth.available) {
      return _guest
          ? const HomeScreen()
          : FirebaseSetupScreen(onContinue: () => setState(() => _guest = true));
    }

    return StreamBuilder<User?>(
      stream: auth.changes,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        return snap.data == null ? const AuthScreen() : const HomeScreen();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: DL.bgTop,
      body: DuelBackground(
        child: Center(child: CircularProgressIndicator(color: DL.cyan)),
      ),
    );
  }
}
