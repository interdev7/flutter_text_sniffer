import 'package:flutter/material.dart';
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';

/// Demonstrates the recommended way to use [TextSniffer] with a large body of
/// text (e.g. a book reader).
///
/// The key idea: do NOT put the whole text into a single [TextSniffer].
/// [RichText] lays out its entire span tree eagerly, so a book-sized string
/// would be laid out (and pattern-matched) all at once.
///
/// Instead, split the text into chunks (paragraphs here) and render each chunk
/// in its own [TextSniffer] inside a [ListView.builder]. The list only builds
/// the chunks that are visible, so both layout and regex matching stay lazy and
/// scale to arbitrarily long texts.
class LongTextExample extends StatelessWidget {
  const LongTextExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Pretend this came from a book file. Each entry is one paragraph.
    final paragraphs = List<String>.generate(
      500,
      (i) =>
          'Paragraph ${i + 1}. Visit https://example.com/page$i for details, '
          'or email reader$i@example.com. Follow #chapter$i for updates. '
          'This is filler body text to make the paragraph long enough to wrap '
          'across multiple lines on screen, just like a real book would.',
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Long text (book) example')),
      body: ListView.builder(
        // Only visible paragraphs are built -> layout & regex stay lazy.
        itemCount: paragraphs.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextSniffer(
            text: paragraphs[index],
            sniffers: [
              EmailSniffer(),
              LinkSniffer(),
            ],
            onTapMatch: (entry, matchText, type, idx) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped: $matchText')),
              );
            },
          ),
        ),
      ),
    );
  }
}
