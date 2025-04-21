import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../models/flashcard.dart';
import '../widgets/flashcard_view.dart';

/// Page for creating or editing a flashcard.
class CardEditPage extends StatefulWidget {
  final String deckId;
  final Flashcard? card;
  const CardEditPage({Key? key, required this.deckId, this.card}) : super(key: key);

  @override
  State<CardEditPage> createState() => _CardEditPageState();
}

class _CardEditPageState extends State<CardEditPage> {
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _tagsController = TextEditingController();
  // only use bytes for image; remove path reference
  Uint8List? _frontImageBytes;
  Uint8List? _backImageBytes;
  final ImagePicker _picker = ImagePicker();
  final _cardBox = Hive.box<Flashcard>('flashcards');
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _frontController.text = widget.card!.front;
      _backController.text = widget.card!.back;
      _tagsController.text = widget.card!.tags.join(', ');
      _frontImageBytes = widget.card!.frontImageBytes;
      _backImageBytes = widget.card!.backImageBytes;
    }
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool front) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      if (front) {
        _frontImageBytes = bytes;
      } else {
        _backImageBytes = bytes;
      }
    });
  }
  
  void _save() async {
    final front = _frontController.text.trim();
    final back = _backController.text.trim();
    if (front.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter front text')),
      );
      return;
    }
    if (back.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter back text')),
      );
      return;
    }
    final tagText = _tagsController.text.trim();
    final tags = tagText.isEmpty
        ? <String>[]
        : tagText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    if (widget.card != null) {
      final card = widget.card!;
      card.front = front;
      card.back = back;
      card.tags = tags;
      card.frontImageBytes = _frontImageBytes;
      card.backImageBytes = _backImageBytes;
      await _cardBox.put(card.id, card);
    } else {
      final id = _uuid.v4();
      final now = DateTime.now();
      final newCard = Flashcard(
        id: id,
        deckId: widget.deckId,
        front: front,
        back: back,
        tags: tags,
        frontImageBytes: _frontImageBytes,
        backImageBytes: _backImageBytes,
        interval: 0,
        easeFactor: 2.5,
        repetition: 0,
        due: now,
        lastGrade: 0,
      );
      await _cardBox.put(id, newCard);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;
    // Gather existing tags for suggestions
    final allTags = _cardBox.values
        .expand((c) => c.tags)
        .toSet()
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Card' : 'New Card')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
              ),
            ),
            if (allTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: allTags.map((tag) {
                  return ActionChip(
                    label: Text(tag),
                    onPressed: () {
                      // Add tag if not already present
                      final current = _tagsController.text.trim();
                      final parts = current.isEmpty
                          ? <String>[]
                          : current.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
                      if (!parts.contains(tag)) {
                        parts.add(tag);
                        final updated = parts.join(', ');
                        setState(() {
                          _tagsController.text = updated;
                          _tagsController.selection = TextSelection.fromPosition(
                            TextPosition(offset: updated.length),
                          );
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            // Front side preview
            FlashcardView(
              text: _frontController.text,
              imageBytes: _frontImageBytes,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                  onPressed: () => _pickImage(ImageSource.gallery, true),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  onPressed: () => _pickImage(ImageSource.camera, true),
                ),
                if (_frontImageBytes != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => setState(() => _frontImageBytes = null),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _frontController,
              decoration: const InputDecoration(
                labelText: 'Front Text',
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              minLines: 3,
              maxLines: null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Back side preview
            FlashcardView(
              text: _backController.text,
              imageBytes: _backImageBytes,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Gallery'),
                  onPressed: () => _pickImage(ImageSource.gallery, false),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  onPressed: () => _pickImage(ImageSource.camera, false),
                ),
                if (_backImageBytes != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => setState(() => _backImageBytes = null),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _backController,
              decoration: const InputDecoration(
                labelText: 'Back Text',
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,
              minLines: 3,
              maxLines: null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}