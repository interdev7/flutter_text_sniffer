// ignore_for_file: public_member_api_docs, sort_constructors_first
library flutter_text_sniffer;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_text_sniffer/sniffer_types.dart';

/// A callback type for handling tap events on matched text segments.
///
/// Parameters:
/// - [match]: The entry from `matchEntries` associated with this match, or
///   `null` when no entry is provided for it. `matchEntries` is optional, so
///   this is frequently `null` — rely on [matchText]/[type]/[index] instead.
/// - [matchText]: The actual text that was matched and tapped.
/// - [type]: The type of the match (phone, email, link, or custom).
/// - [index]: The zero-based position of the match across **all** matches in
///   the text, regardless of type (not per-type). Use [type] to disambiguate.
/// - [error]: Reserved for reporting errors during a tap. Currently always
///   `null`; kept for forward compatibility.
typedef OnTapMatch<T> = void Function(T? match, String matchText, SnifferType type, int index, Object? error);

/// A callback type for building custom widgets for matched text segments.
///
/// Parameters:
/// - [text]: The matched text segment
/// - [index]: The index of the match in the original text
/// - [type]: The type of the match (phone, email, link, or custom)
/// - [matchEntry]: The corresponding entry from [matchEntries] if available
typedef MatchBuilder<T> = Widget Function(String text, int index, SnifferType type, T? matchEntry);

/// A widget that detects specific patterns within a text and makes them interactive.
///
/// [TextSniffer] allows you to define custom patterns within the text using regular
/// expressions, apply styles to the detected parts, and handle user interactions
/// with these parts, such as taps on links or specific words.
class TextSniffer<T> extends StatefulWidget {
  /// The full text to be displayed.
  final String text;

  /// The style applied to non-matching text.
  final TextStyle? textStyle;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// The directionality of the text.
  ///
  /// This decides how [textAlign] values like [TextAlign.start] and
  /// [TextAlign.end] are interpreted.
  ///
  /// This is also used to disambiguate how to render bidirectional text. For
  /// example, if the [text] is an English phrase followed by a Hebrew phrase,
  /// in a [TextDirection.ltr] context the English phrase will be on the left
  /// and the Hebrew phrase to its right, while in a [TextDirection.rtl]
  /// context, the English phrase will be on the right and the Hebrew phrase on
  /// its left.
  ///
  /// Defaults to the ambient [Directionality], if any. If there is no ambient
  /// [Directionality], then this must not be null.
  final TextDirection? textDirection;

  /// Whether the text should break at soft line breaks.
  ///
  /// If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// Deprecated. Will be removed in a future version of Flutter. Use
  /// [textScaler] instead.
  ///
  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  @Deprecated(
    'Use textScaler instead. '
    'Use of textScaleFactor was deprecated in preparation for the upcoming nonlinear text scaling support. '
    'This feature was deprecated after v3.12.0-2.0.pre.',
  )
  double get textScaleFactor => textScaler.textScaleFactor;

  /// {@macro flutter.painting.textPainter.textScaler}
  final TextScaler textScaler;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int? maxLines;

  /// Used to select a font when the same Unicode character can
  /// be rendered differently, depending on the locale.
  ///
  /// It's rarely necessary to set this property. By default its value
  /// is inherited from the enclosing app with `Localizations.localeOf(context)`.
  ///
  /// See [RenderParagraph.locale] for more information.
  final Locale? locale;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.painting.textPainter.textWidthBasis}
  final TextWidthBasis textWidthBasis;

  /// {@macro dart.ui.textHeightBehavior}
  final TextHeightBehavior? textHeightBehavior;

  /// The [SelectionRegistrar] this rich text is subscribed to.
  ///
  /// If this is set, [selectionColor] must be non-null.
  final SelectionRegistrar? selectionRegistrar;

  /// The color to use when painting the selection.
  ///
  /// This is ignored if [selectionRegistrar] is null.
  ///
  /// See the section on selections in the [RichText] top-level API
  /// documentation for more details on enabling selection in [RichText]
  /// widgets.
  final Color? selectionColor;

  /// Semantic label for accessibility.
  final String? semanticsLabel;

  /// A list of sniffer types to apply for text matching.
  ///
  /// Each sniffer type uses its own regular expression to find matches in the text.
  /// Available sniffer types:

  ///
  ///```dart
  /// class CustomSnifferType extends SnifferType {
  ///   @override
  ///   RegExp get pattern => RegExp(r'\[(.*?)\]');
  ///
  ///   @override
  ///   TextStyle? get style => const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold);
  ///
  ///   @override
  ///   String toString() => 'custom';
  /// }
  ///
  /// TextSniffer(
  ///   text: "[Email] example@domain.com. Visit http://example.com. ABC",
  ///   maxLines: 2,
  ///   snifferTypes: const [
  ///     EmailSnifferType(),
  ///     LinkSnifferType(),
  ///     CustomSnifferType(), // Use it
  ///   ],
  /// )
  ///```
  ///

  final List<SnifferType> snifferTypes;

  /// The list of entries corresponding to each match in the text.
  ///
  /// This list is used in combination with the [onTapMatch] callback to provide
  /// additional data for each match. For example, if the text contains links, the
  /// entries in this list could be the URLs associated with those links.
  ///
  /// The length of this list should match the number of detected matches.
  final List<T> matchEntries;

  /// A callback function that is triggered when a matching part of the text is tapped.
  ///
  /// This callback receives the corresponding object of type [T] from the [matchEntries] list.
  /// It allows you to define an action when a user taps on a specific matched part of the text.
  /// For example, it can be used to open a URL, show a dialog, or perform navigation.
  ///
  /// If the list of [matchEntries] is empty or the index is out of bounds, the callback
  /// will not be called. Ensure that the length of [matchEntries] matches the number of
  /// expected matches in the text to avoid index errors.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// TextSniffer<String>(
  ///   text: "Visit [Flutter] or [Google]",
  ///   matchEntries: ['https://flutter.dev', 'https://google.com'],
  ///   onTapMatch: (link, match, type, index, error) {
  ///     print('Tapped link: $link');
  ///     // Open the link or perform an action
  ///   },
  /// )
  /// ```
  ///
  /// In this example, the words "Flutter" and "Google" will be rendered as interactive
  /// links. When tapped, the corresponding URL is printed.
  /// - [match]: The object of type [T] associated with the tapped match.
  final OnTapMatch<T>? onTapMatch;

  /// A custom builder function for creating the [TextSpan] for each match.
  ///
  /// This function allows you to define how each matching part of the text should be
  /// displayed and interacted with. If provided, it will override the default
  /// behavior and style for matches.
  ///
  /// Parameters:
  /// - [match]: The string that matched the pattern.
  /// - [index]: The index of the match within the text.
  /// - [type]: The type of the match (phone, email, link, or custom).
  /// - [matchEntry]: The corresponding entry from [matchEntries] if available.
  final MatchBuilder<T>? matchBuilder;

  const TextSniffer({
    super.key,
    required this.text,
    this.snifferTypes = const [],
    this.textStyle,
    this.semanticsLabel,
    this.locale,
    this.selectionColor,
    this.textScaler = TextScaler.noScaling,
    this.selectionRegistrar,
    this.strutStyle,
    this.softWrap = true,
    this.textDirection,
    this.textHeightBehavior,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.onTapMatch,
    this.textWidthBasis = TextWidthBasis.parent,
    this.matchBuilder,
    this.matchEntries = const [],
  });

  @override
  State<TextSniffer<T>> createState() => _TextSnifferState<T>();
}

class _TextSnifferState<T> extends State<TextSniffer<T>> {
  /// The result of parsing [TextSniffer.text] against the sniffer patterns.
  ///
  /// This is the expensive part (running the regex over potentially large text)
  /// and is recomputed only when [TextSniffer.text] or the patterns change —
  /// not on every rebuild.
  List<_Segment> _segments = const [];

  /// One reusable tap recognizer per matched segment, indexed by match index.
  ///
  /// Recognizers hold resources and must be disposed. They are created lazily,
  /// reused across rebuilds, and their `onTap` reads [widget] at tap time, so
  /// changing [TextSniffer.onTapMatch]/[TextSniffer.matchEntries] does not
  /// require re-parsing or recreating them.
  final List<TapGestureRecognizer> _recognizers = [];

  /// Signature of the current patterns, used to detect when re-parsing is needed.
  String _patternSignature = '';

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(covariant TextSniffer<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || _signatureOf(oldWidget.snifferTypes) != _patternSignature) {
      _parse();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  String _signatureOf(List<SnifferType> types) =>
      types.map((e) => '${e.runtimeType}:${e.pattern?.pattern}').join('|');

  /// Builds (or rebuilds) the combined pattern and parses the text into segments.
  void _parse() {
    _disposeRecognizers();
    _patternSignature = _signatureOf(widget.snifferTypes);

    RegExp? combinedPattern;
    if (widget.snifferTypes.isNotEmpty) {
      final patterns = widget.snifferTypes
          .map((e) => e.pattern?.pattern)
          .where((p) => p != null && p.isNotEmpty)
          .join('|');
      if (patterns.isNotEmpty) {
        combinedPattern = RegExp(patterns, caseSensitive: false);
      }
    }

    _segments = _parseSegments(widget.text, combinedPattern, widget.snifferTypes);
  }

  /// Handles a tap on a matched segment, reading the current widget so that the
  /// latest [TextSniffer.onTapMatch]/[TextSniffer.matchEntries] are always used.
  ///
  /// [matchEntries] is optional and per-match: an entry may simply not exist for
  /// the tapped match. In that case the callback receives a null entry and a
  /// null error, so [matchText]/[type]/[index] are always usable.
  void _handleTap(String matchText, SnifferType type, int index) {
    final entries = widget.matchEntries;
    final entry = (index >= 0 && index < entries.length) ? entries[index] : null;
    widget.onTapMatch?.call(entry, matchText, type, index, null);
  }

  /// Returns a reusable recognizer for the match at [index], creating it once.
  TapGestureRecognizer _recognizerFor(String matchText, SnifferType type, int index) {
    while (_recognizers.length <= index) {
      final i = _recognizers.length;
      _recognizers.add(TapGestureRecognizer());
      // Bind once; the closure reads the current widget at tap time.
      final segment = _segments.firstWhere((s) => s.isMatch && s.matchIndex == i);
      _recognizers[i].onTap = () => _handleTap(segment.text, segment.type!, i);
    }
    return _recognizers[index];
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (final segment in _segments) {
      if (!segment.isMatch) {
        spans.add(TextSpan(
          text: segment.text,
          style: widget.textStyle ?? DefaultTextStyle.of(context).style,
        ));
        continue;
      }

      final type = segment.type!;
      final index = segment.matchIndex;

      if (widget.matchBuilder != null) {
        final entry = (index >= 0 && index < widget.matchEntries.length) ? widget.matchEntries[index] : null;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => _handleTap(segment.text, type, index),
            child: widget.matchBuilder!(segment.text, index, type, entry),
          ),
        ));
        continue;
      }

      spans.add(TextSpan(
        text: segment.text,
        style: type.style,
        recognizer: _recognizerFor(segment.text, type, index),
      ));
    }

    return RichText(
      textAlign: widget.textAlign,
      locale: widget.locale,
      selectionColor: widget.selectionColor,
      selectionRegistrar: widget.selectionRegistrar,
      softWrap: widget.softWrap,
      strutStyle: widget.strutStyle,
      textDirection: widget.textDirection,
      textHeightBehavior: widget.textHeightBehavior,
      textScaler: widget.textScaler,
      textWidthBasis: widget.textWidthBasis,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      text: TextSpan(children: spans, semanticsLabel: widget.semanticsLabel),
    );
  }
}

/// A single piece of the parsed text: either a matched or a non-matched run.
class _Segment {
  final String text;
  final bool isMatch;

  /// Zero-based position across all matches; valid only when [isMatch] is true.
  final int matchIndex;

  /// The sniffer type that produced this match; non-null only when [isMatch].
  final SnifferType? type;

  const _Segment.match(this.text, this.matchIndex, this.type) : isMatch = true;
  const _Segment.nonMatch(this.text)
      : isMatch = false,
        matchIndex = -1,
        type = null;
}

/// Splits [text] into matched/non-matched segments using [pattern].
///
/// This is the only place the regex runs over the full text, so it is the work
/// that callers cache (see [_TextSnifferState._parse]).
List<_Segment> _parseSegments(String text, RegExp? pattern, List<SnifferType> snifferTypes) {
  final result = <_Segment>[];
  if (pattern == null) {
    if (text.isNotEmpty) result.add(_Segment.nonMatch(text));
    return result;
  }

  final regex = RegexCache.get(pattern);
  final matchList = regex.allMatches(text).toList();

  int currentIndex = 0;
  int matchIndex = 0;

  for (final match in matchList) {
    if (match.start > currentIndex) {
      result.add(_Segment.nonMatch(text.substring(currentIndex, match.start)));
    }

    String matchedText = match[0] ?? '';

    SnifferType? type;
    for (final entry in snifferTypes) {
      if (entry.pattern?.matchAsPrefix(matchedText) != null) {
        type = entry;
        break;
      }
    }

    if (type is! LinkSnifferType && type is! EmailSnifferType) {
      for (int i = 1; i <= match.groupCount; i++) {
        if (match[i] != null && match[i]!.isNotEmpty) {
          matchedText = match[i]!;
          break;
        }
      }
    }

    result.add(_Segment.match(matchedText, matchIndex, type!));
    currentIndex = match.end;
    matchIndex++;
  }

  if (currentIndex < text.length) {
    result.add(_Segment.nonMatch(text.substring(currentIndex)));
  }

  return result;
}

/// Cache for regular expressions to avoid creating new instances on each call.
class RegexCache {
  static final Map<String, RegExp> _cache = {};

  /// Get a cached regular expression equivalent to [pattern].
  ///
  /// The cache key includes the relevant flags (case sensitivity, multiline,
  /// etc.) so that two patterns with the same source but different flags do not
  /// collide. This preserves [pattern]'s flags (e.g. `caseSensitive: false`)
  /// instead of recreating it with the RegExp defaults.
  static RegExp get(RegExp pattern) {
    final key = '${pattern.isCaseSensitive ? 's' : 'i'}'
        '${pattern.isMultiLine ? 'm' : ''}'
        '${pattern.isDotAll ? 'd' : ''}'
        '${pattern.isUnicode ? 'u' : ''}'
        ':${pattern.pattern}';
    return _cache.putIfAbsent(key, () => pattern);
  }
}