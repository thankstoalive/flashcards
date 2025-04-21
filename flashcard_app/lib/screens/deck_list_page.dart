import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../services/backup_service.dart';

import '../models/flashcard.dart';

import '../models/deck.dart';
import 'deck_page.dart';
import 'card_list_page.dart';

/// Displays the list of decks and allows creating/deleting decks.
class DeckListPage extends StatefulWidget {
  const DeckListPage({Key? key}) : super(key: key);

  @override
  State<DeckListPage> createState() => _DeckListPageState();
}

class _DeckListPageState extends State<DeckListPage> {
  late Box<Deck> _deckBox;
  // Flashcard box to compute per-deck review info
  late Box<Flashcard> _cardBox;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _deckBox = Hive.box<Deck>('decks');
    _cardBox = Hive.box<Flashcard>('flashcards');
  }

  void _addDeck() async {
    final nameController = TextEditingController();
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void tryCreate() {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                setState(() {
                  errorText = 'Please enter a deck name';
                });
              } else {
                Navigator.pop(context, name);
              }
            }
            return AlertDialog(
              title: const Text('New Deck'),
              content: TextField(
                controller: nameController,
                autofocus: true,
                onSubmitted: (_) => tryCreate(),
                decoration: InputDecoration(
                  labelText: 'Deck Name',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: tryCreate,
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != null) {
      final id = _uuid.v4();
      await _deckBox.put(id, Deck(id: id, name: result));
    }
  }

  void _deleteDeck(String id) {
    _deckBox.delete(id);
  }
  
  /// Trigger backup/export functionality (web or stub)
  Future<void> _exportBackup() => BackupService.exportBackup(context);
  
  /// Trigger import functionality (web or stub)
  Future<void> _importBackup() => BackupService.importBackup(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'All Cards',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CardListPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Backup',
            onPressed: _exportBackup,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            tooltip: 'Import',
            onPressed: _importBackup,
          ),
          // 테마 토글 버튼
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
      body: ValueListenableBuilder(
        valueListenable: _deckBox.listenable(),
        builder: (context, Box<Deck> deckBox, _) {
          return ValueListenableBuilder(
            valueListenable: _cardBox.listenable(),
            builder: (context, Box<Flashcard> cardBox, _) {
              final decks = deckBox.values.toList();
              if (decks.isEmpty) {
                return const Center(child: Text('No decks. Add one!'));
              }
              return ListView.builder(
                itemCount: decks.length,
                itemBuilder: (context, index) {
                  final deck = decks[index];
                  final now = DateTime.now();
                  final deckCards = cardBox.values
                      .where((c) => c.deckId == deck.id)
                      .toList();
                  final dueCards = deckCards
                      .where((c) => !c.due.isAfter(now))
                      .toList();
                  // Build subtitle: total cards, due info
                  final total = deckCards.length;
                  final dueCount = dueCards.length;
                  String subtitleText = '$total cards';
                  if (total > 0) {
                    if (dueCount > 0) {
                      dueCards.sort((a, b) => a.due.compareTo(b.due));
                      final next = dueCards
                          .first.due
                          .toLocal()
                          .toString()
                          .split(' ')[0];
                      subtitleText += ' | Next: $next • Due: $dueCount';
                    } else {
                      subtitleText += ' | No cards due';
                    }
                  }
                  return ListTile(
                    isThreeLine: true,
                    title: Text(deck.name),
                    subtitle: Text(
                      subtitleText,
                      style: const TextStyle(
                          fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DeckPage(deckId: deck.id),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _deleteDeck(deck.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDeck,
        child: const Icon(Icons.add),
      ),
    );
  }
}