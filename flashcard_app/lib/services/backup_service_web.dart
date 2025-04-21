// Web implementation using dart:html for file import/export
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/deck.dart';
import '../models/flashcard.dart';

/// Web implementation for backup/import functionality.
class BackupService {
  /// Exports all decks and flashcards to a JSON file and triggers download.
  static Future<void> exportBackup(BuildContext context) async {
    final deckBox = Hive.box<Deck>('decks');
    final cardBox = Hive.box<Flashcard>('flashcards');
    final decks = deckBox.values.map((d) => d.toMap()).toList();
    final cards = cardBox.values.map((c) => c.toMap()).toList();
    final backup = jsonEncode({'decks': decks, 'flashcards': cards});
    final blob = html.Blob([backup], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download',
          'flashcard_backup_${DateTime.now().toIso8601String()}.json')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Opens a file picker to import a JSON backup file and restores data.
  static Future<void> importBackup(BuildContext context) async {
    final input = html.FileUploadInputElement()..accept = '.json';
    input.click();
    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsText(file);
      reader.onLoad.first.then((_) async {
        try {
          final content = reader.result as String;
          final data = jsonDecode(content) as Map<String, dynamic>;
          if (data.containsKey('decks') && data.containsKey('flashcards')) {
            final deckBox = Hive.box<Deck>('decks');
            final cardBox = Hive.box<Flashcard>('flashcards');
            await deckBox.clear();
            await cardBox.clear();
            for (final d in (data['decks'] as List)) {
              final deck = Deck.fromMap(d as Map<String, dynamic>);
              await deckBox.put(deck.id, deck);
            }
            for (final c in (data['flashcards'] as List)) {
              final card = Flashcard.fromMap(c as Map<String, dynamic>);
              await cardBox.put(card.id, card);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Import successful.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid backup file format.')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: $e')),
          );
        }
      });
    });
  }
}