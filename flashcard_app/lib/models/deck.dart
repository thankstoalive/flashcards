import 'package:hive/hive.dart';

/// Represents a collection of flashcards.
class Deck {
  /// Unique identifier
  final String id;
  /// Human-readable name
  String name;

  Deck({required this.id, required this.name});
  /// Convert to JSON-serializable map
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}

/// Hive adapter for [Deck]
class DeckAdapter extends TypeAdapter<Deck> {
  @override
  final int typeId = 0;

  @override
  Deck read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final field = reader.readByte();
      fields[field] = reader.read();
    }
    return Deck(
      id: fields[0] as String,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Deck obj) {
    writer.writeByte(2);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.name);
  }
}