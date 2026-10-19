import 'package:flutter/material.dart';

import '../theme/duel_theme.dart';
import 'cards_screen.dart';
import 'deck_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DL.bgTop,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [CardsScreen(), DeckListScreen(), ProfileScreen()],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                10, 8, 10, 8 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFF020A22),
              border: Border(top: BorderSide(color: DL.edge, width: 2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DuelButton(
                    label: 'การ์ด',
                    icon: Icons.style,
                    selected: _tab == 0,
                    onTap: () => setState(() => _tab = 0),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DuelButton(
                    label: 'เด็ค',
                    icon: Icons.inventory_2,
                    selected: _tab == 1,
                    onTap: () => setState(() => _tab = 1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DuelButton(
                    label: 'โปรไฟล์',
                    icon: Icons.person,
                    selected: _tab == 2,
                    onTap: () => setState(() => _tab = 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
