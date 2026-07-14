import 'package:flutter/material.dart';
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';

/// A real-world example: an annotated book reader.
///
/// This shows a public-domain excerpt from Lewis Carroll's
/// "Alice's Adventures in Wonderland" and demonstrates how [TextSniffer] can
/// turn plain prose into an interactive reading experience:
///
/// - **Character names** are highlighted and tappable to show who they are.
/// - **Glossary terms** (rare/old-fashioned words) are highlighted and tappable
///   to reveal their definition.
///
/// This is the kind of thing you might build for an e-book reader, a study
/// tool, or a language-learning app — the reader taps a word and gets context
/// without leaving the page.
class BookExcerptExample extends StatelessWidget {
  const BookExcerptExample({super.key});

  static const _excerpt =
      'Alice was beginning to get very tired of sitting by her sister on the '
      'bank, and of having nothing to do: once or twice she had peeped into the '
      'book her sister was reading, but it had no pictures or conversations in '
      'it, "and what is the use of a book," thought Alice, "without pictures or '
      'conversations?"\n\n'
      'So she was considering in her own mind whether the pleasure of making a '
      'daisy-chain would be worth the trouble of getting up and picking the '
      'daisies, when suddenly a White Rabbit with pink eyes ran close by her.\n\n'
      'There was nothing so very remarkable in that; nor did Alice think it so '
      'very much out of the way to hear the Rabbit say to itself, "Oh dear! Oh '
      'dear! I shall be late!" But when the Rabbit actually took a watch out of '
      'its waistcoat-pocket, and looked at it, and then hurried on, Alice '
      'started to her feet, for it flashed across her mind that she had never '
      'before seen a rabbit with either a waistcoat-pocket, or a watch to take '
      'out of it, and burning with curiosity, she ran across the field after it.';

  /// Short annotations shown when a highlighted word is tapped.
  static const _glossary = <String, String>{
    'Alice': 'The young protagonist of the story, a curious seven-year-old.',
    'White Rabbit':
        'A talking rabbit in a waistcoat whom Alice follows down the rabbit hole.',
    'Rabbit': 'The White Rabbit — the creature Alice chases through the field.',
    'daisy-chain':
        'A string of daisies threaded together, a common pastime for children.',
    'waistcoat-pocket':
        'A small pocket in a waistcoat (a vest) — unusual for a rabbit to have!',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Annotated book reader")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Alice's Adventures in Wonderland",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Chapter I — Down the Rabbit-Hole',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap a highlighted name or word to learn more.',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            const Divider(height: 32),
            TextSniffer<String>(
              text: _excerpt,
              textStyle: const TextStyle(
                fontSize: 18,
                height: 1.6,
                color: Colors.black87,
              ),
              sniffers: [
                CharacterSnifferType(),
                GlossarySnifferType(),
              ],
              // Look the annotation up by the matched word instead of keeping a
              // positional list in sync with the prose — far more robust.
              entryResolver: (matchText, type, index) => _glossary[matchText],
              onTapMatch: (annotation, matchText, type, index) {
                if (annotation == null) return;
                showModalBottomSheet(
                  context: context,
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matchText,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(annotation),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Highlights character names in blue and bold.
class CharacterSnifferType extends Sniffer {
  @override
  RegExp get pattern => RegExp(r'\bWhite Rabbit\b|\bAlice\b|\bRabbit\b');

  @override
  TextStyle? get style => const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      );

  @override
  String toString() => 'character';
}

/// Highlights glossary terms with a dotted-looking underline color.
class GlossarySnifferType extends Sniffer {
  @override
  RegExp get pattern => RegExp(r'\bdaisy-chain\b|\bwaistcoat-pocket\b');

  @override
  TextStyle? get style => const TextStyle(
        color: Colors.teal,
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.dashed,
      );

  @override
  String toString() => 'glossary';
}
