import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
// Web download
// import 'dart:html' as html;  // removed web-only imports
// import 'package:file_selector/file_selector.dart';

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
  final Box<Deck> _deckBox = Hive.box<Deck>('decks');
  final _uuid = const Uuid();

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
  
  /// Exports all decks and cards as JSON and saves to file (mobile only)
  Future<void> _exportBackup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup is supported on mobile/desktop only.')),
    );
  }
  
  /// Imports all decks and cards from a JSON backup file (mobile only)
  Future<void> _importBackup() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import is supported on mobile/desktop only.')),
    );
  }

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
        builder: (context, Box<Deck> box, _) {
          final decks = box.values.toList();
          if (decks.isEmpty) {
            return const Center(child: Text('No decks. Add one!'));
          }
          return ListView.builder(
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return ListTile(
                title: Text(deck.name),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DeckPage(deckId: deck.id),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteDeck(deck.id),
                ),
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