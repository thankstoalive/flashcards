import 'dart:convert';
import 'package:hive/hive.dart';
import 'dart:typed_data';

/// Represents a single flashcard with spaced repetition metadata.
class Flashcard {
  /// Unique identifier
  final String id;
  /// Parent deck ID
  String deckId;
  /// Text shown on the front
  String front;
  /// Text shown on the back
  String back;
  /// Current interval in days
  int interval;
  /// Ease factor for SM-2
  double easeFactor;
  /// Number of consecutive correct repetitions
  int repetition;
  /// Tags for categorization
  List<String> tags;
  /// Optional front side image bytes
  Uint8List? frontImageBytes;
  /// Optional back side image bytes
  Uint8List? backImageBytes;
  /// Next due date for review
  DateTime due;
  /// Last grade given (1=Hard, 2=Normal, 3=Easy)
  int lastGrade;

  Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.tags,
    this.frontImageBytes,
    this.backImageBytes,
    required this.interval,
    required this.easeFactor,
    required this.repetition,
    required this.due,
    required this.lastGrade,
  });

  /// Convert to JSON-serializable map, embedding images as base64 strings
  Map<String, dynamic> toMap() => {
        'id': id,
        'deckId': deckId,
        'front': front,
        'back': back,
        'tags': tags,
        'interval': interval,
        'easeFactor': easeFactor,
        'repetition': repetition,
        'due': due.toIso8601String(),
        'lastGrade': lastGrade,
        'frontImage':
            frontImageBytes != null ? base64Encode(frontImageBytes!) : null,
        'backImage': backImageBytes != null ? base64Encode(backImageBytes!) : null,
      };
}

/// Hive adapter for [Flashcard]
class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 1;

  @override
  Flashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final field = reader.readByte();
      fields[field] = reader.read();
    }
    final tags = fields.containsKey(9)
        ? (fields[9] as List).cast<String>()
        : <String>[];
    final frontImageBytes = fields.containsKey(10)
        ? (fields[10] as Uint8List?)
        : null;
    final backImageBytes = fields.containsKey(11)
        ? (fields[11] as Uint8List?)
        : null;
    return Flashcard(
      id: fields[0] as String,
      deckId: fields[1] as String,
      front: fields[2] as String,
      back: fields[3] as String,
      tags: tags,
      frontImageBytes: frontImageBytes,
      backImageBytes: backImageBytes,
      interval: fields[4] as int,
      easeFactor: fields[5] as double,
      repetition: fields[6] as int,
      due: fields[7] as DateTime,
      lastGrade: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer.writeByte(12);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.deckId);
    writer.writeByte(2);
    writer.write(obj.front);
    writer.writeByte(3);
    writer.write(obj.back);
    writer.writeByte(4);
    writer.write(obj.tags);
    writer.writeByte(5);
    writer.write(obj.interval);
    writer.writeByte(6);
    writer.write(obj.easeFactor);
    writer.writeByte(7);
    writer.write(obj.repetition);
    writer.writeByte(8);
    writer.write(obj.due);
    writer.writeByte(9);
    writer.write(obj.lastGrade);
    writer.writeByte(10);
    writer.write(obj.frontImageBytes);
    writer.writeByte(11);
    writer.write(obj.backImageBytes);
  }
}