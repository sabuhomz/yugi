import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/card_repository.dart';
import 'services/deck_store.dart';
import 'services/translation_service.dart';
import 'theme/duel_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache
    ..maximumSize = 3000
    ..maximumSizeBytes = 400 << 20;
  final decks = DeckStore();
  final translator = TranslationService();
  final cards = CardRepository();
  await Future.wait([decks.load(), translator.load()]);
  cards.load(); // โหลดต่อเบื้องหลัง แสดง loading ในหน้าการ์ด

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CardRepository>.value(value: cards),
        ChangeNotifierProvider<DeckStore>.value(value: decks),
        Provider<TranslationService>.value(value: translator),
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
      home: const HomeScreen(),
    );
  }
}
