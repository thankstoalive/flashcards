import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/deck.dart';
import '../models/flashcard.dart';
import 'study_page.dart';

/// Page displaying all flashcards with filters for deck, tags, and difficulty.
class CardListPage extends StatefulWidget {
  const CardListPage({Key? key}) : super(key: key);

  @override
  State<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends State<CardListPage> {
  late Box<Flashcard> _cardBox;
  late Box<Deck> _deckBox;
  String? _selectedDeckId;
  final Set<int> _selectedDifficulties = <int>{};
  final Set<String> _selectedTags = <String>{};

  @override
  void initState() {
    super.initState();
    _cardBox = Hive.box<Flashcard>('flashcards');
    _deckBox = Hive.box<Deck>('decks');
  }

  List<Flashcard> get _filteredCards {
    final all = _cardBox.values.toList();
    final now = DateTime.now();
    return all.where((c) {
      if (_selectedDeckId != null && c.deckId != _selectedDeckId) {
        return false;
      }
      if (_selectedDifficulties.isNotEmpty && !_selectedDifficulties.contains(c.lastGrade)) {
        return false;
      }
      if (_selectedTags.isNotEmpty && !_selectedTags.every((t) => c.tags.contains(t))) {
        return false;
      }
      return true;
    }).toList();
  }

  Set<String> get _allTags {
    return _cardBox.values.expand((c) => c.tags).toSet();
  }

  String _gradeLabel(int grade) {
    switch (grade) {
      case 1:
        return 'Hard';
      case 2:
        return 'Normal';
      case 3:
        return 'Easy';
      default:
        return '-';
    }
  }

  Future<void> _openFilter() async {
    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setSt) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Deck'),
                  DropdownButton<String?>(
                    isExpanded: true,
                    value: _selectedDeckId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Decks')),
                      ..._deckBox.values.map(
                        (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
                      ),
                    ],
                    onChanged: (v) => setSt(() => _selectedDeckId = v),
                  ),
                  const SizedBox(height: 12),
                  const Text('Difficulty'),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Hard'),
                        selected: _selectedDifficulties.contains(1),
                        onSelected: (v) => setSt(() {
                          v ? _selectedDifficulties.add(1) : _selectedDifficulties.remove(1);
                        }),
                      ),
                      FilterChip(
                        label: const Text('Normal'),
                        selected: _selectedDifficulties.contains(2),
                        onSelected: (v) => setSt(() {
                          v ? _selectedDifficulties.add(2) : _selectedDifficulties.remove(2);
                        }),
                      ),
                      FilterChip(
                        label: const Text('Easy'),
                        selected: _selectedDifficulties.contains(3),
                        onSelected: (v) => setSt(() {
                          v ? _selectedDifficulties.add(3) : _selectedDifficulties.remove(3);
                        }),
                      ),
                    ],
                  ),
                  if (_allTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Tags'),
                    Wrap(
                      spacing: 8,
                      children: _allTags.map((tag) {
                        return FilterChip(
                          label: Text(tag),
                          selected: _selectedTags.contains(tag),
                          onSelected: (v) => setSt(() {
                            v ? _selectedTags.add(tag) : _selectedTags.remove(tag);
                          }),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setSt(() {
                          _selectedDeckId = null;
                          _selectedDifficulties.clear();
                          _selectedTags.clear();
                        }),
                        child: const Text('Reset'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _openFilter,
          ),
          ValueListenableBuilder<Box<Flashcard>>(
            valueListenable: _cardBox.listenable(),
            builder: (context, box, _) {
              final dueNow = DateTime.now();
              final dueCount = _filteredCards
                  .where((c) => !c.due.isAfter(dueNow))
                  .length;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.school),
                    tooltip: 'Study Filtered',
                    onPressed: () {
                      final dueCards = _filteredCards
                          .where((c) => !c.due.isAfter(dueNow))
                          .toList();
                      if (dueCards.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No filtered cards are due for review.')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudyPage(cards: dueCards),
                        ),
                      );
                    },
                  ),
                  if (dueCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          dueCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _cardBox.listenable(),
        builder: (context, Box<Flashcard> box, _) {
          final cards = _filteredCards;
          if (cards.isEmpty) {
            return const Center(child: Text('No cards match filters.'));
          }
          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final deck = _deckBox.get(card.deckId);
              return ListTile(
                title: Text(card.front),
                leading: card.frontImageBytes != null
                    ? Image.memory(
                        card.frontImageBytes!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : null,
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.back),
                    const SizedBox(height: 4),
                    Text(
                      'Deck: ${deck?.name ?? ''} | Tags: ${card.tags.join(', ')} | Difficulty: ${_gradeLabel(card.lastGrade)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}