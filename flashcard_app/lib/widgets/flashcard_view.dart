import 'dart:typed_data';
import 'package:flutter/material.dart';

/// A reusable flashcard display with optional image and text.
class FlashcardView extends StatelessWidget {
  /// The text content to show (front or back).
  final String text;
  /// Optional image bytes to display above the text.
  final Uint8List? imageBytes;

  const FlashcardView({Key? key, required this.text, this.imageBytes})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imageBytes != null) ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: Image.memory(
                  imageBytes!,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}