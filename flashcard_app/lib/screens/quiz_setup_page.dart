import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';

import '../models/deck.dart';
import 'quiz_session_page.dart';

/// 퀴즈 모드: 사용자 지정 덱 선택 화면
class QuizSetupPage extends StatefulWidget {
  const QuizSetupPage({Key? key}) : super(key: key);

  @override
  State<QuizSetupPage> createState() => _QuizSetupPageState();
}

class _QuizSetupPageState extends State<QuizSetupPage> {
  late Box<Deck> _deckBox;
  final Set<String> _selectedDeckIds = <String>{};
  int _intervalSec = 3;

  @override
  void initState() {
    super.initState();
    _deckBox = Hive.box<Deck>('decks');
  }

  @override
  Widget build(BuildContext context) {
    final decks = _deckBox.values.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀴즈 모드 - 덱 선택'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) {
              return IconButton(
                icon: Icon(
                  mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                ),
                tooltip: '테마 전환',
                onPressed: () {
                  themeNotifier.value =
                      mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                },
              );
            },
          ),
        ],
      ),
      body: decks.isEmpty
          ? const Center(child: Text('등록된 덱이 없습니다.'))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ...decks.map((deck) {
                  final selected = _selectedDeckIds.contains(deck.id);
                  return CheckboxListTile(
                    title: Text(deck.name),
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedDeckIds.add(deck.id);
                        } else {
                          _selectedDeckIds.remove(deck.id);
                        }
                      });
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),
                const Text('카드 전환 간격 (초):', style: TextStyle(fontSize: 16)),
                Slider(
                  value: _intervalSec.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_intervalSec',
                  onChanged: (v) => setState(() => _intervalSec = v.round()),
                ),
                Center(child: Text('$_intervalSec 초', style: const TextStyle(fontSize: 14))),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedDeckIds.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizSessionPage(
                            deckIds: _selectedDeckIds.toList(),
                            intervalSeconds: _intervalSec,
                          ),
                        ),
                      );
                    },
              child: const Text('퀴즈 시작'),
            ),
          ),
        ),
      ),
    );
  }
}