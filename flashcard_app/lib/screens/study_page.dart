import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/flashcard.dart';
import '../widgets/flashcard_view.dart';

/// Page for studying flashcards in a deck using SM-2 algorithm.
class StudyPage extends StatefulWidget {
  /// If studying from a single deck, set [deckId].
  final String? deckId;
  /// If studying filtered cards across decks, set [cards].
  final List<Flashcard>? cards;
  const StudyPage({Key? key, this.deckId, this.cards})
      : assert(deckId != null || cards != null,
            'Either deckId or cards must be provided'),
        super(key: key);

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  late List<Flashcard> _dueCards;
  int _currentIndex = 0;
  bool _showFront = true;
  late Box<Flashcard> _cardBox;

  @override
  void initState() {
    super.initState();
    _cardBox = Hive.box<Flashcard>('flashcards');
    final now = DateTime.now();
    if (widget.cards != null) {
      // Use provided filtered cards
      _dueCards = widget.cards!
          .where((c) => !c.due.isAfter(now))
          .toList();
    } else {
      // Study by deck
      _dueCards = _cardBox.values
          .where((c) => c.deckId == widget.deckId && !c.due.isAfter(now))
          .toList();
    }
  }

  void _answer(int grade) {
    final card = _dueCards[_currentIndex];
    // Map grade(1=Hard,2=Normal,3=Easy) to SM-2 quality (2,3,5)
    final quality = grade == 1 ? 2 : (grade == 2 ? 3 : 5);
    if (quality < 3) {
      card.repetition = 0;
      card.interval = 1;
    } else {
      if (card.repetition == 0) {
        card.interval = 1;
      } else if (card.repetition == 1) {
        card.interval = 6;
      } else {
        card.interval = (card.interval * card.easeFactor).round();
      }
      card.repetition += 1;
    }
    // Update ease factor
    double ef = card.easeFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (ef < 1.3) ef = 1.3;
    card.easeFactor = ef;
    // Schedule next review
    card.due = DateTime.now().add(Duration(days: card.interval));
    card.lastGrade = grade;
    // Save
    _cardBox.put(card.id, card);
    // Move to next
    setState(() {
      _currentIndex += 1;
      _showFront = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_dueCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study')),
        body: const Center(child: Text('No cards due for review.')),
      );
    }
    if (_currentIndex >= _dueCards.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('Study')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Session complete!'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }
    final card = _dueCards[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: const Text('Study')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: InkWell(
                onTap: _showFront ? () => setState(() => _showFront = false) : null,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FlashcardView(
                    text: _showFront ? card.front : card.back,
                    imageBytes: _showFront ? card.frontImageBytes : card.backImageBytes,
                  ),
                ),
              ),
            ),
            if (!_showFront) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () => _answer(1),
                    child: const Text('Hard'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    onPressed: () => _answer(2),
                    child: const Text('Normal'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _answer(3),
                    child: const Text('Easy'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}