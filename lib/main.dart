import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/auth_service.dart';
import 'services/card_repository.dart';
import 'services/deck_store.dart';
import 'services/limit_store.dart';
import 'services/translation_service.dart';
import 'theme/duel_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 3000
    ..maximumSizeBytes = 400 << 20;
  // Firebase: ถ้ายังไม่ตั้งค่า (ไม่ได้รัน flutterfire configure) แอปยังเปิดได้
  var firebaseOk = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseOk = true;
  } catch (e) {
    debugPrint('Firebase ยังใช้งานไม่ได้: $e');
  }
  final auth = AuthService(available: firebaseOk);

  final decks = DeckStore();
  final translator = TranslationService();
  final limits = LimitStore();
  final cards = CardRepository();
  await Future.wait([decks.load(), translator.load(), limits.load()]);
  cards.load(); // โหลดต่อเบื้องหลัง แสดง loading ในหน้าการ์ด

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CardRepository>.value(value: cards),
        ChangeNotifierProvider<DeckStore>.value(value: decks),
        ChangeNotifierProvider<LimitStore>.value(value: limits),
        Provider<TranslationService>.value(value: translator),
        Provider<AuthService>.value(value: auth),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speed Duel Cards',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const AuthGate(),
    );
  }
}
