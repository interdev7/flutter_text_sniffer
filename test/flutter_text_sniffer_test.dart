import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';

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
          onTapMatch: (entry, matchText, type, index) {
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

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: 'See [A] and [B]',
          sniffers: [_BracketType()],
          matchEntries: const ['entryA', 'entryB'],
          onTapMatch: (entry, matchText, type, index) {
            tappedEntry = entry;
            tappedText = matchText;
            tappedIndex = index;
          },
        ),
      );

      recognizerFor(spans, 'B').onTap!();

      expect(tappedEntry, 'entryB');
      expect(tappedText, 'B');
      expect(tappedIndex, 1);
    });

    testWidgets('empty matchEntries yields null entry', (tester) async {
      String? entry = 'sentinel';

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: 'See [A]',
          sniffers: [_BracketType()],
          onTapMatch: (e, matchText, type, index) {
            entry = e;
          },
        ),
      );

      recognizerFor(spans, 'A').onTap!();

      expect(entry, isNull);
    });

    testWidgets('duplicate matched text keeps distinct indices',
        (tester) async {
      final indices = <int>[];

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: '[X] then [X]',
          sniffers: [_BracketType()],
          onTapMatch: (entry, matchText, type, index) {
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
      String? entry = 'sentinel';

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: '[A] [B] [C]',
          sniffers: [_BracketType()],
          matchEntries: const ['only-one'],
          onTapMatch: (e, matchText, type, index) {
            entry = e;
          },
        ),
      );

      // Third match has no entry.
      recognizerFor(spans, 'C').onTap!();
      expect(entry, isNull);
    });

    testWidgets('onError catches and handles exceptions thrown in onTapMatch',
        (tester) async {
      Object? caughtError;
      StackTrace? caughtStackTrace;

      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: 'See [A]',
          sniffers: [_BracketType()],
          onTapMatch: (entry, matchText, type, index) {
            throw Exception('Test tap error');
          },
          onError: (error, stackTrace) {
            caughtError = error;
            caughtStackTrace = stackTrace;
          },
        ),
      );

      recognizerFor(spans, 'A').onTap!();

      expect(caughtError, isA<Exception>());
      expect(caughtError.toString(), contains('Test tap error'));
      expect(caughtStackTrace, isNotNull);
    });

    testWidgets(
        'rethrows exception if onTapMatch throws and onError is not provided',
        (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer<String>(
          text: 'See [A]',
          sniffers: [_BracketType()],
          onTapMatch: (entry, matchText, type, index) {
            throw Exception('Unhandled error');
          },
        ),
      );

      expect(() => recognizerFor(spans, 'A').onTap!(), throwsException);
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
            onTapMatch: (entry, matchText, type, index) {
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

      // With no explicit textScaler the deprecated getter reports no scaling.
      // ignore: deprecated_member_use_from_same_package
      expect(const TextSniffer(text: 'x').textScaleFactor, 1.0);
    });

    testWidgets('strict LinkSniffer skips bare hosts but matches www/scheme',
        (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'see example.com and www.example.com and https://a.dev',
          sniffers: [LinkSniffer()],
        ),
      );

      final matched =
          spans.where((s) => s.recognizer != null).map((s) => s.text).toList();
      expect(matched, ['www.example.com', 'https://a.dev']);
    });

    testWidgets('LinkSniffer.loosePattern matches scheme-less hosts',
        (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'see example.com now',
          sniffers: [LinkSniffer(pattern: LinkSniffer.loosePattern)],
        ),
      );

      expect(spans.any((s) => s.text == 'example.com'), isTrue);
    });

    testWidgets('PhoneSniffer matches common phone formats', (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'Call +1 (555) 123-4567 or 8-800-555-35-35 today',
          sniffers: [PhoneSniffer()],
        ),
      );

      final matched =
          spans.where((s) => s.recognizer != null).map((s) => s.text).toList();
      expect(matched, ['+1 (555) 123-4567', '8-800-555-35-35']);
    });

    testWidgets('HashtagSniffer matches unicode hashtags', (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'love #flutter and #дартс a#b',
          sniffers: [HashtagSniffer()],
        ),
      );

      final matched =
          spans.where((s) => s.recognizer != null).map((s) => s.text).toList();
      expect(matched, ['#flutter', '#дартс']);
    });

    testWidgets('MentionSniffer matches @-mentions', (tester) async {
      final spans = await _spansOf(
        tester,
        TextSniffer(
          text: 'ping @alice and a@b.com',
          sniffers: [MentionSniffer()],
        ),
      );

      final matched =
          spans.where((s) => s.recognizer != null).map((s) => s.text).toList();
      expect(matched, ['@alice']);
    });

    test('new types expose readable names and accept hoverStyle', () {
      expect(PhoneSniffer().toString(), 'phone');
      expect(HashtagSniffer().toString(), 'hashtag');
      expect(MentionSniffer().toString(), 'mention');

      const hover = TextStyle(decoration: TextDecoration.underline);
      expect(EmailSniffer(hoverStyle: hover).hoverStyle, hover);
      expect(LinkSniffer(hoverStyle: hover).hoverStyle, hover);
      expect(PhoneSniffer(hoverStyle: hover).hoverStyle, hover);
      expect(HashtagSniffer(hoverStyle: hover).hoverStyle, hover);
      expect(MentionSniffer(hoverStyle: hover).hoverStyle, hover);
    });
  });

  group('text scaling', () {
    testWidgets('inherits the ambient MediaQuery textScaler by default',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: TextSniffer(text: 'a@b.com', sniffers: [EmailSniffer()]),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.textScaler, const TextScaler.linear(2));
    });

    testWidgets('an explicit textScaler overrides the ambient one',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: TextSniffer(text: 'x', textScaler: TextScaler.noScaling),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.textScaler, TextScaler.noScaling);
    });
  });

  group('hover', () {
    testWidgets('applies hoverStyle on enter and reverts on exit',
        (tester) async {
      final sniffers = [
        EmailSniffer(
          hoverStyle: const TextStyle(decoration: TextDecoration.underline),
        ),
      ];

      TextSpan matchSpan() {
        final richText = tester.widget<RichText>(find.byType(RichText));
        return _collectTextSpans(richText.text)
            .firstWhere((s) => s.text == 'a@b.com');
      }

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer(text: 'mail a@b.com now', sniffers: sniffers),
        ),
      ));

      expect(matchSpan().style?.decoration, isNull);
      expect(matchSpan().onEnter, isNotNull);

      matchSpan().onEnter!(const PointerEnterEvent());
      await tester.pump();
      expect(matchSpan().style?.decoration, TextDecoration.underline);
      // The base style is preserved under the merged hover style.
      expect(matchSpan().style?.color, Colors.redAccent);

      matchSpan().onExit!(const PointerExitEvent());
      await tester.pump();
      expect(matchSpan().style?.decoration, isNull);
    });
  });

  group('long press', () {
    testWidgets('fires onLongPressMatch and suppresses the tap',
        (tester) async {
      final events = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer<String>(
            text: '[A] rest of the text',
            sniffers: [_BracketType()],
            onTapMatch: (entry, matchText, type, index) {
              events.add('tap:$matchText');
            },
            onLongPressMatch: (entry, matchText, type, index) {
              events.add('long:$matchText:$index');
            },
          ),
        ),
      ));

      // The match is the first glyph, so press just inside the paragraph.
      final pos = tester.getTopLeft(find.byType(RichText)) +
          Offset(7, tester.getSize(find.byType(RichText)).height / 2);
      final gesture = await tester.startGesture(pos);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();

      expect(events, ['long:A:0']);
    });

    testWidgets('a long hold without onLongPressMatch still delivers the tap',
        (tester) async {
      final events = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer<String>(
            text: '[A] rest of the text',
            sniffers: [_BracketType()],
            onTapMatch: (entry, matchText, type, index) {
              events.add('tap:$matchText');
            },
          ),
        ),
      ));

      final pos = tester.getTopLeft(find.byType(RichText)) +
          Offset(7, tester.getSize(find.byType(RichText)).height / 2);
      final gesture = await tester.startGesture(pos);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();

      expect(events, ['tap:A']);
    });

    testWidgets('a quick tap is delivered as a tap, not a long press',
        (tester) async {
      final events = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer<String>(
            text: '[A] rest of the text',
            sniffers: [_BracketType()],
            onTapMatch: (entry, matchText, type, index) {
              events.add('tap:$matchText');
            },
            onLongPressMatch: (entry, matchText, type, index) {
              events.add('long:$matchText');
            },
          ),
        ),
      ));

      final pos = tester.getTopLeft(find.byType(RichText)) +
          Offset(7, tester.getSize(find.byType(RichText)).height / 2);
      final gesture = await tester.startGesture(pos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.up();
      await tester.pump();

      expect(events, ['tap:A']);
    });

    testWidgets('a cancelled gesture fires neither callback', (tester) async {
      final events = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer<String>(
            text: '[A] rest of the text',
            sniffers: [_BracketType()],
            onTapMatch: (entry, matchText, type, index) {
              events.add('tap');
            },
            onLongPressMatch: (entry, matchText, type, index) {
              events.add('long');
            },
          ),
        ),
      ));

      final pos = tester.getTopLeft(find.byType(RichText)) +
          Offset(7, tester.getSize(find.byType(RichText)).height / 2);
      final gesture = await tester.startGesture(pos);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.cancel();
      await tester.pump(kLongPressTimeout);

      expect(events, isEmpty);
    });

    testWidgets('disposing mid-press cancels the pending long-press timer',
        (tester) async {
      final events = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer<String>(
            text: '[A] rest of the text',
            sniffers: [_BracketType()],
            onLongPressMatch: (entry, matchText, type, index) {
              events.add('long');
            },
          ),
        ),
      ));

      final pos = tester.getTopLeft(find.byType(RichText)) +
          Offset(7, tester.getSize(find.byType(RichText)).height / 2);
      final gesture = await tester.startGesture(pos);
      await tester.pump(const Duration(milliseconds: 50));

      // Remove the widget while the pointer is down.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump(kLongPressTimeout);
      await gesture.up();

      expect(events, isEmpty);
    });

    testWidgets('routes onLongPressMatch errors to onError', (tester) async {
      Object? caughtError;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer<String>(
            text: '[A] rest of the text',
            sniffers: [_BracketType()],
            onLongPressMatch: (entry, matchText, type, index) {
              throw Exception('long-press error');
            },
            onError: (error, stackTrace) {
              caughtError = error;
            },
          ),
        ),
      ));

      final pos = tester.getTopLeft(find.byType(RichText)) +
          Offset(7, tester.getSize(find.byType(RichText)).height / 2);
      final gesture = await tester.startGesture(pos);
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await gesture.up();

      expect(caughtError.toString(), contains('long-press error'));
    });

    testWidgets('matchBuilder widgets receive long presses too',
        (tester) async {
      final events = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer<String>(
            text: 'See [A]',
            sniffers: [_BracketType()],
            onLongPressMatch: (entry, matchText, type, index) {
              events.add('long:$matchText');
            },
            matchBuilder: (matchText, index, type, entry) =>
                Text(matchText, key: ValueKey('m$index')),
          ),
        ),
      ));

      await tester.longPress(find.byKey(const ValueKey('m0')));
      expect(events, ['long:A']);
    });
  });

  group('accessibility', () {
    testWidgets('matchBuilder matches are exposed as buttons to semantics',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextSniffer<String>(
            text: 'See [A]',
            sniffers: [_BracketType()],
            matchBuilder: (matchText, index, type, entry) => Text(matchText),
          ),
        ),
      ));

      expect(
        tester.getSemantics(find.text('A')),
        isSemantics(isButton: true, hasTapAction: true),
      );
    });
  });

  group('selection', () {
    testWidgets('registers with an enclosing SelectionArea automatically',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            child: TextSniffer(text: 'a@b.com', sniffers: [EmailSniffer()]),
          ),
        ),
      ));

      final richText = tester.widget<RichText>(find.byType(RichText).last);
      expect(richText.selectionRegistrar, isNotNull);
      expect(richText.selectionColor, isNotNull);
    });

    testWidgets('an explicit selectionColor wins inside a SelectionArea',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SelectionArea(
            child: TextSniffer(
              text: 'a@b.com',
              sniffers: [EmailSniffer()],
              selectionColor: Colors.amber,
            ),
          ),
        ),
      ));

      final richText = tester.widget<RichText>(find.byType(RichText).last);
      expect(richText.selectionColor, Colors.amber);
    });

    testWidgets('falls back to the default selection color without any style',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextSniffer(
            text: 'a@b.com',
            sniffers: [EmailSniffer()],
            selectionRegistrar: _FakeRegistrar(),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.selectionColor, DefaultSelectionStyle.defaultColor);
    });
  });

  group('RegexCache', () {
    test('returns the cached instance for an equivalent pattern', () {
      final a = RegExp(r'cache-hit-test');
      final b = RegExp(r'cache-hit-test');
      expect(identical(RegexCache.get(a), RegexCache.get(b)), isTrue);
    });

    test('evicts the oldest entry once maxEntries is exceeded', () {
      for (int i = 0; i < RegexCache.maxEntries * 2; i++) {
        RegexCache.get(RegExp('filler-$i'));
      }

      // Old entries were evicted; the cache never grows past its cap.
      expect(RegexCache.size, RegexCache.maxEntries);
    });
  });
}

/// A no-op [SelectionRegistrar] for testing registrar plumbing.
class _FakeRegistrar implements SelectionRegistrar {
  @override
  void add(Selectable selectable) {}

  @override
  void remove(Selectable selectable) {}
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
