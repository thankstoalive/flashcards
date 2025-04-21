import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';


/// A reusable flashcard display with optional image and text.
class FlashcardView extends StatelessWidget {
  /// The text content to show (front or back).
  final String text;
  /// Optional image bytes to display above the text.
  final Uint8List? imageBytes;

  const FlashcardView({Key? key, required this.text, this.imageBytes})
      : super(key: key);

  /// Split [text] by code fences and return widgets: plain text and highlighted code blocks.
  List<Widget> _buildContent() {
    final pattern = RegExp(r'```(?:([a-zA-Z]+))?\n([\s\S]*?)```', multiLine: true);
    final widgets = <Widget>[];
    int start = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > start) {
        widgets.add(Text(
          text.substring(start, match.start),
          style: const TextStyle(fontSize: 18),
        ));
      }
      final lang = match.group(1) ?? 'python';
      final code = match.group(2) ?? '';
      widgets.add(Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: HighlightView(
          code,
          language: lang,
          theme: githubTheme,
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 16,
          ),
        ),
      ));
      start = match.end;
    }
    if (start < text.length) {
      widgets.add(Text(
        text.substring(start),
        style: const TextStyle(fontSize: 18),
      ));
    }
    return widgets;
  }

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
            // Render content with manual code-fence parsing
            ..._buildContent(),
          ],
        ),
      ),
    );
  }
}