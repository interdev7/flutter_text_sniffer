import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';
import 'package:flutter_text_sniffer/sniffer_types.dart';

/// Collects all leaf [TextSpan]s (those carrying `text`) from a span tree,
/// in order.
List<TextSpan> _collectTextSpans(InlineSpan root) {
  final result = <TextSpan>[];
  void visit(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text != null) result.add(span);
      for (final child in span.children ?? const <InlineSpan>[]) {
        visit(child);
      }
    }
  }

  visit(root);
  return result;
}

/// Pumps a [TextSniffer] and returns the leaf text spans it produced.
Future<List<TextSpan>> _spansOf(WidgetTester tester, Widget sniffer) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: sniffer)),
  );
  final richText = tester.widget<RichText>(find.byType(RichText));
  return _collectTextSpans(richText.text);
}

void main() {
  group('parsing', () {
    testWidgets('splits matched and non-matched runs in order', (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'Email me at a@b.com please',
          snifferTypes: [EmailSnifferType()],
        ),
      );

      final texts = spans.map((s) => s.text).toList();
      expect(texts, ['Email me at ', 'a@b.com', ' please']);
    });

    testWidgets('matches emails case-insensitively', (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'Write to USER@EXAMPLE.COM now',
          snifferTypes: [EmailSnifferType()],
        ),
      );

      expect(spans.any((s) => s.text == 'USER@EXAMPLE.COM'), isTrue);
    });

    testWidgets('null/empty patterns do not match every position',
        (tester) async {
      final spans = await _spansOf(
        tester,
        const TextSniffer(
          text: 'plain text',
          snifferTypes: <SnifferType>[],
        ),
      );

      // No patterns -> the whole text is a single non-matching run.
      expect(spans.map((s) => s.text).toList(), ['plain text']);
    });
  });

  group('tap handling', () {
    /// Finds the recognizer attached to the span whose text equals [text].
    TapGestureRecognizer recognizerFor(List<TextSpan> spans, String text) {
      final span = spans.firstWhere((s) => s.text == text);
      return span.recognizer! as TapGestureRecognizer;
    }

    testWidgets('delivers entry, matchText and index for a tapped match',
        (tester) async {
      String? tappedEntry;
      String? tappedText;
      int? tappedIndex;
      Object? tappedError = 'sentinel';

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: 'See [A] and [B]',
          snifferTypes: [_BracketType()],
          matchEntries: const ['entryA', 'entryB'],
          onTapMatch: (entry, matchText, type, index, error) {
            tappedEntry = entry;
            tappedText = matchText;
            tappedIndex = index;
            tappedError = error;
          },
        ),
      );

      recognizerFor(spans, 'B').onTap!();

      expect(tappedEntry, 'entryB');
      expect(tappedText, 'B');
      expect(tappedIndex, 1);
      expect(tappedError, isNull);
    });

    testWidgets('empty matchEntries yields null entry and no error',
        (tester) async {
      Object? error = 'sentinel';
      String? entry = 'sentinel';

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: 'See [A]',
          snifferTypes: [_BracketType()],
          onTapMatch: (e, matchText, type, index, err) {
            entry = e;
            error = err;
          },
        ),
      );

      recognizerFor(spans, 'A').onTap!();

      expect(entry, isNull);
      expect(error, isNull);
    });

    testWidgets('duplicate matched text keeps distinct indices', (tester) async {
      final indices = <int>[];

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: '[X] then [X]',
          snifferTypes: [_BracketType()],
          onTapMatch: (entry, matchText, type, index, error) {
            indices.add(index);
          },
        ),
      );

      // Both spans say "X" but must carry their own index (0 and 1).
      final xs = spans.where((s) => s.text == 'X').toList();
      expect(xs.length, 2);
      (xs[0].recognizer! as TapGestureRecognizer).onTap!();
      (xs[1].recognizer! as TapGestureRecognizer).onTap!();
      expect(indices, [0, 1]);
    });

    testWidgets('out-of-range matchEntries yields null entry, no throw',
        (tester) async {
      Object? error = 'sentinel';
      String? entry = 'sentinel';

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: '[A] [B] [C]',
          snifferTypes: [_BracketType()],
          matchEntries: const ['only-one'],
          onTapMatch: (e, matchText, type, index, err) {
            entry = e;
            error = err;
          },
        ),
      );

      // Third match has no entry.
      recognizerFor(spans, 'C').onTap!();
      expect(entry, isNull);
      expect(error, isNull);
    });
  });

  group('rebuild behavior', () {
    testWidgets('re-parses when text changes', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer(
            text: 'a@b.com',
            snifferTypes: [EmailSnifferType()],
          ),
        ),
      ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer(
            text: 'changed c@d.com',
            snifferTypes: [EmailSnifferType()],
          ),
        ),
      ));

      final richText = tester.widget<RichText>(find.byType(RichText));
      final texts = _collectTextSpans(richText.text).map((s) => s.text);
      expect(texts, contains('c@d.com'));
      expect(texts, contains('changed '));
    });
  });
}

/// Test sniffer that matches `[word]` and exposes the inner word as match text.
class _BracketType extends SnifferType {
  @override
  RegExp get pattern => RegExp(r'\[(.*?)\]');

  @override
  TextStyle? get style => const TextStyle(color: Colors.blue);

  @override
  String toString() => 'bracket';
}
