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
          sniffers: [EmailSniffer()],
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
          sniffers: [EmailSniffer()],
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
          sniffers: <Sniffer>[],
        ),
      );

      // No patterns -> the whole text is a single non-matching run.
      expect(spans.map((s) => s.text).toList(), ['plain text']);
    });
  });

  group('case sensitivity', () {
    testWidgets('respects a case-sensitive pattern (no forced lowercasing)',
        (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'Alice met alice',
          sniffers: [_CaseSensitiveType()],
        ),
      );

      // Only the capitalized "Alice" matches; lowercase "alice" stays inline.
      final matched = spans.where((s) => s.recognizer != null).toList();
      expect(matched.map((s) => s.text), ['Alice']);
    });
  });

  group('priority / overlap', () {
    testWidgets('earlier type in sniffers wins on overlap', (tester) async {
      // Both types can match "wonder"; the first listed should win.
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'a wonder b',
          sniffers: [_WordType('wonder', Colors.red), _AnyWordType()],
        ),
      );

      final match = spans.firstWhere((s) => s.text == 'wonder');
      expect(match.style?.color, Colors.red);
    });
  });

  group('entryResolver', () {
    testWidgets('takes precedence over matchEntries, keyed by matched text',
        (tester) async {
      String? tappedEntry;

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: 'See [A] and [B]',
          sniffers: [_BracketType()],
          matchEntries: const ['posA', 'posB'],
          entryResolver: (matchText, type, index) => 'resolved-$matchText',
          onTapMatch: (entry, matchText, type, index, error) {
            tappedEntry = entry;
          },
        ),
      );

      (spans.firstWhere((s) => s.text == 'B').recognizer!
              as TapGestureRecognizer)
          .onTap!();
      expect(tappedEntry, 'resolved-B');
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
          sniffers: [_BracketType()],
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
          sniffers: [_BracketType()],
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

    testWidgets('duplicate matched text keeps distinct indices',
        (tester) async {
      final indices = <int>[];

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: '[X] then [X]',
          sniffers: [_BracketType()],
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
          sniffers: [_BracketType()],
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
            sniffers: [EmailSniffer()],
          ),
        ),
      ));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer(
            text: 'changed c@d.com',
            sniffers: [EmailSniffer()],
          ),
        ),
      ));

      final richText = tester.widget<RichText>(find.byType(RichText));
      final texts = _collectTextSpans(richText.text).map((s) => s.text);
      expect(texts, contains('c@d.com'));
      expect(texts, contains('changed '));
    });

    testWidgets('re-parses when sniffers pattern changes', (tester) async {
      const text = 'ping a@b.com [tag]';

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: TextSniffer(text: text, sniffers: <Sniffer>[]),
        ),
      ));

      // Same text, but the pattern signature changes -> must re-parse.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer(text: text, sniffers: [_BracketType()]),
        ),
      ));

      final richText = tester.widget<RichText>(find.byType(RichText));
      final texts = _collectTextSpans(richText.text).map((s) => s.text);
      expect(texts, contains('tag'));
    });
  });

  group('matchBuilder', () {
    testWidgets('builds a WidgetSpan per match and delivers tap',
        (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer<String>(
            text: 'See [A] and [B]',
            sniffers: [_BracketType()],
            matchEntries: const ['entryA', 'entryB'],
            onTapMatch: (entry, matchText, type, index, error) {
              tappedIndex = index;
            },
            matchBuilder: (matchText, index, type, entry) =>
                Text('$matchText:$entry', key: ValueKey('m$index')),
          ),
        ),
      ));

      expect(find.byKey(const ValueKey('m0')), findsOneWidget);
      expect(find.text('A:entryA'), findsOneWidget);
      expect(find.text('B:entryB'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('m1')));
      expect(tappedIndex, 1);
    });
  });

  group('built-in sniffer types', () {
    testWidgets('LinkSniffer matches urls with default style/pattern',
        (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'visit https://example.com now',
          sniffers: [LinkSniffer()],
        ),
      );

      expect(spans.any((s) => s.text == 'https://example.com'), isTrue);
    });

    test('types expose readable names via toString', () {
      expect(EmailSniffer().toString(), 'email');
      expect(LinkSniffer().toString(), 'link');
    });

    testWidgets('exposes deprecated textScaleFactor from textScaler',
        (tester) async {
      const sniffer = TextSniffer(
        text: 'x',
        sniffers: <Sniffer>[],
        textScaler: TextScaler.linear(1.5),
      );
      // ignore: deprecated_member_use_from_same_package
      expect(sniffer.textScaleFactor, 1.5);
    });
  });
}

/// Case-sensitive sniffer: matches only the capitalized word "Alice".
class _CaseSensitiveType extends Sniffer {
  @override
  RegExp get pattern => RegExp(r'\bAlice\b'); // caseSensitive: true by default

  @override
  TextStyle? get style => const TextStyle(color: Colors.blue);

  @override
  String toString() => 'case';
}

/// Matches a specific [word], styled with [color].
class _WordType extends Sniffer {
  _WordType(this.word, this.color);
  final String word;
  final Color color;

  @override
  RegExp get pattern => RegExp('\\b$word\\b');

  @override
  TextStyle? get style => TextStyle(color: color);

  @override
  String toString() => 'word:$word';
}

/// Matches any word, styled in grey.
class _AnyWordType extends Sniffer {
  @override
  RegExp get pattern => RegExp(r'\b\w+\b');

  @override
  TextStyle? get style => const TextStyle(color: Colors.grey);

  @override
  String toString() => 'anyword';
}

/// Test sniffer that matches `[word]` and exposes the inner word as match text.
class _BracketType extends Sniffer {
  @override
  RegExp get pattern => RegExp(r'\[(.*?)\]');

  @override
  TextStyle? get style => const TextStyle(color: Colors.blue);

  @override
  String toString() => 'bracket';
}
