// ignore_for_file: public_member_api_docs, sort_constructors_first
library flutter_text_sniffer;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_text_sniffer/sniffer_types.dart';

/// A callback type for processing matched text segments.
///
/// Parameters:
/// - [text]: The matched text segment
/// - [index]: The index of the match in the original text
/// - [matchCount]: The total number of matches found
/// - [type]: The type of the match (phone, email, link, or custom)
typedef _MatchCallback<T> = T Function(String text, int index, int matchCount, SnifferType type);

/// A callback type for processing non-matched text segments.
///
/// Parameters:
/// - [nonMatch]: The non-matched text segment
typedef _NonMatchCallback<T> = T Function(String nonMatch);

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
class TextSniffer<T> extends StatelessWidget {
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

  /// Internal method to handle tap events on matched text segments.
  ///
  /// Calls the [onTapMatch] callback with the appropriate parameters and handles any errors
  /// that might occur during the callback execution.
  void onTapMatchFn(List<T> matchEntries, String match, SnifferType type, int index) {
    // [matchEntries] is optional and per-match: an entry may simply not exist
    // for the tapped match (no list provided, or the match has no associated
    // entry — common when mixing types where only some need entries). In that
    // case we deliver the tap with a null entry rather than treating it as an
    // error, so [match]/[type]/[index] are always usable.
    final entry = (index >= 0 && index < matchEntries.length) ? matchEntries[index] : null;
    onTapMatch?.call(entry, match, type, index, null);
  }

  @override
  Widget build(BuildContext context) {
    // Determine the pattern based on snifferTypes
    RegExp? combinedPattern;
    if (snifferTypes.isNotEmpty) {
      final patterns = snifferTypes
          .map((e) => e.pattern?.pattern)
          .where((p) => p != null && p.isNotEmpty)
          .join('|');
      if (patterns.isNotEmpty) {
        combinedPattern = RegExp(patterns, caseSensitive: false);
      }
    }

    // Split the text and process each part
    final spans = text._customSplitMapJoin<InlineSpan>(
      pattern: combinedPattern,
      snifferTypes: snifferTypes,
      onMatch: (text, index, count, type) {
        // If a custom matchBuilder is provided, use it
        if (matchBuilder != null) {
          final entry = matchEntries.isNotEmpty ? matchEntries[index] : null;
          return WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => onTapMatchFn(matchEntries, text, type, index),
              child: matchBuilder!(text, index, type, entry),
            ),
          );
        }
        return TextSpan(
          text: text,
          style: type.style,
          recognizer: TapGestureRecognizer()..onTap = () => onTapMatchFn(matchEntries, text, type, index),
        );
      },
      onNonMatch: (nonMatch) {
        return TextSpan(
          text: nonMatch,
          style: textStyle ?? const TextStyle(color: Colors.black),
        );
      },
    );

    return RichText(
      textAlign: textAlign,
      locale: locale,
      selectionColor: selectionColor,
      selectionRegistrar: selectionRegistrar,
      softWrap: softWrap,
      strutStyle: strutStyle,
      textDirection: textDirection,
      textHeightBehavior: textHeightBehavior,
      textScaler: textScaler,
      textWidthBasis: textWidthBasis,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(children: spans, semanticsLabel: semanticsLabel),
    );
  }
}

/// Extension on the [String] class that provides a custom `splitMapJoin`
/// implementation.
///
/// This extension allows splitting a string based on a regular expression pattern,
/// processing the matched and non-matched parts, and then re-joining them into
/// a list of type [T].
extension on String {
  /// Internal method that handles the text splitting and processing logic.
  ///
  /// Parameters:
  /// - [pattern]: The regular expression pattern to match against
  /// - [onMatch]: Callback function for processing matched segments
  /// - [onNonMatch]: Callback function for processing non-matched segments
  /// - [patternByType]: Map of sniffer types to their corresponding patterns
  ///
  /// Returns a list of processed segments of type [T].
  List<T> _customSplitMapJoin<T>({
    required RegExp? pattern,
    required _MatchCallback<T> onMatch,
    required _NonMatchCallback<T> onNonMatch,
    required List<SnifferType>? snifferTypes,
  }) {
    List<T> result = [];
    int currentIndex = 0;
    int matchIndex = 0;

    final inlineSpansCache = InlineSpanCache<T>();

    if (pattern != null) {
      final regex = RegexCache.get(pattern);
      final matchList = regex.allMatches(this).toList();

      final matchCount = matchList.length;

      for (var j = 0; j < matchList.length; j++) {
        final match = matchList[j];
        if (match.start > currentIndex) {
          final nonMatchText = substring(currentIndex, match.start);
          result.add(inlineSpansCache.getSpan(nonMatchText, onNonMatch));
          // result.add(onNonMatch(substring(currentIndex, match.start)));
        }

        String matchedText = match[0] ?? '';

        SnifferType? type;
        if (snifferTypes != null && snifferTypes.isNotEmpty) {
          for (var entry in snifferTypes) {
            if (entry.pattern?.matchAsPrefix(matchedText) != null) {
              type = entry;
              break;
            }
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
        // Matches must NOT be cached by text: identical matched strings can
        // appear multiple times with different indices, and a cached span would
        // carry the wrong index into onTapMatch (wrong matchEntries lookup).
        result.add(onMatch(matchedText, matchIndex, matchCount, type!));
        currentIndex = match.end;
        matchIndex++;
      }
    }

    if (currentIndex < length) {
      result.add(onNonMatch(substring(currentIndex)));
    }

    return result;
  }
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

class InlineSpanCache<T> {
  final _cache = <String, T>{};

  T getSpan(String text, T Function(String) builder) {
    if (_cache.containsKey(text)) {
      return _cache[text]!;
    }
    final span = builder(text);
    _cache[text] = span;
    return span;
  }
}