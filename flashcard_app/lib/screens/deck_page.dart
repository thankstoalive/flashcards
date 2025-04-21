import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/deck.dart';
import '../models/flashcard.dart';
import 'card_edit_page.dart';
import 'study_page.dart';

/// Page showing cards in a deck, with options to add/edit/delete and start study.
class DeckPage extends StatefulWidget {
  final String deckId;
  const DeckPage({Key? key, required this.deckId}) : super(key: key);

  @override
  State<DeckPage> createState() => _DeckPageState();
}

class _DeckPageState extends State<DeckPage> {
  late Box<Deck> _deckBox;
  late Box<Flashcard> _cardBox;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _deckBox = Hive.box<Deck>('decks');
    _cardBox = Hive.box<Flashcard>('flashcards');
  }

  void _addCard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CardEditPage(deckId: widget.deckId),
      ),
    );
  }

  void _deleteCard(String id) {
    _cardBox.delete(id);
  }

  @override
  Widget build(BuildContext context) {
    final deck = _deckBox.get(widget.deckId);
    return Scaffold(
      appBar: AppBar(
        title: Text(deck?.name ?? 'Deck'),
        actions: [
          IconButton(
            icon: const Icon(Icons.school),
            tooltip: 'Study',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StudyPage(deckId: widget.deckId),
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: _cardBox.listenable(),
        builder: (context, Box<Flashcard> box, _) {
          final cards = box.values
              .where((c) => c.deckId == widget.deckId)
              .toList();
          if (cards.isEmpty) {
            return const Center(child: Text('No cards in this deck.'));
          }
          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return ListTile(
                isThreeLine: true,
                leading: card.frontImageBytes != null
                    ? Image.memory(
                        card.frontImageBytes!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : null,
                title: Text(card.front),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(card.back),
                    const SizedBox(height: 4),
                    Text(
                      'Next review: ${card.due.toLocal().toString().split(' ')[0]}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardEditPage(
                              deckId: widget.deckId,
                              card: card,
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deleteCard(card.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add_card),
      ),
    );
  }
}