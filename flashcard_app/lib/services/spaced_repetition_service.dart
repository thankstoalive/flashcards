import 'package:hive_flutter/hive_flutter.dart';
import '../models/flashcard.dart';

/// Service to apply SM-2 spaced repetition algorithm on flashcards.
class SpacedRepetitionService {
  SpacedRepetitionService._();

  /// Grades a [card] with a simple 3-level [grade]:
  /// 1 = Hard, 2 = Normal, 3 = Easy.
  /// Internally maps to SM-2 quality values (2,3,5) and updates
  /// interval, easeFactor, repetition, due date, and lastGrade.
  /// Saves the updated card to the Hive box 'flashcards'.
  static Future<void> gradeCard(Flashcard card, int grade) async {
    // Map 3-level grade to SM-2 quality scale
    final int quality =
        (grade == 1) ? 2 : ((grade == 2) ? 3 : ((grade == 3) ? 5 : grade));
    // Reset repetition if quality below threshold
    if (quality < 3) {
      card.repetition = 0;
      card.interval = 1;
    } else {
      // First and second repetitions have fixed intervals
      if (card.repetition == 0) {
        card.interval = 1;
      } else if (card.repetition == 1) {
        card.interval = 6;
      } else {
        // Subsequent intervals multiplied by ease factor
        card.interval = (card.interval * card.easeFactor).round();
      }
      card.repetition += 1;
    }
    // Update ease factor
    double ef = card.easeFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    card.easeFactor = ef < 1.3 ? 1.3 : ef;
    // Record grade and compute next due date
    card.lastGrade = grade;
    card.due = DateTime.now().add(Duration(days: card.interval));
    // Persist changes
    final box = Hive.box<Flashcard>('flashcards');
    await box.put(card.id, card);
  }
}