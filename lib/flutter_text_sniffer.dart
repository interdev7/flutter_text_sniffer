library flutter_text_sniffer;

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_text_sniffer/sniffers.dart';

export 'package:flutter_text_sniffer/sniffers.dart';

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
typedef OnTapMatch<T> = void Function(
    T? match, String matchText, Sniffer type, int index);

/// A callback type for building custom widgets for matched text segments.
///
/// Parameters:
/// - [text]: The matched text segment
/// - [index]: The index of the match in the original text
/// - [type]: The type of the match (phone, email, link, or custom)
/// - [matchEntry]: The corresponding entry from [matchEntries] if available
typedef MatchBuilder<T> = Widget Function(
    String text, int index, Sniffer type, T? matchEntry);

/// A callback that resolves the entry associated with a match.
///
/// Prefer this over [TextSniffer.matchEntries] when your data is keyed by the
/// matched text (or its type) rather than by position: it is robust to the
/// order and count of matches changing as the text changes.
///
/// Parameters:
/// - [matchText]: The text that was matched.
/// - [type]: The [Sniffer] that produced the match.
/// - [index]: The zero-based position of the match across all matches.
typedef EntryResolver<T> = T? Function(
    String matchText, Sniffer type, int index);

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
  double get textScaleFactor =>
      (textScaler ?? TextScaler.noScaling).textScaleFactor;

  /// {@macro flutter.painting.textPainter.textScaler}
  ///
  /// Defaults to the ambient [MediaQuery]'s text scaler (respecting the
  /// system font-size accessibility setting), or [TextScaler.noScaling] if
  /// there is no ambient [MediaQuery].
  final TextScaler? textScaler;

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
  /// Defaults to the ambient [SelectionContainer]'s registrar, if any, so the
  /// text is selectable inside a [SelectionArea] without extra wiring.
  final SelectionRegistrar? selectionRegistrar;

  /// The color to use when painting the selection.
  ///
  /// Defaults to the ambient [DefaultSelectionStyle.selectionColor].
  ///
  /// This is ignored if no selection registrar is available (see
  /// [selectionRegistrar]).
  final Color? selectionColor;

  /// Semantic label for accessibility.
  final String? semanticsLabel;

  /// A list of sniffer types to apply for text matching.
  ///
  /// Each sniffer type uses its own regular expression to find matches in the
  /// text. Built-in sniffer types: [EmailSniffer], [LinkSniffer],
  /// [PhoneSniffer], [HashtagSniffer], [MentionSniffer]. You can also define
  /// your own:
  ///
  ///```dart
  /// class CustomSnifferType extends Sniffer {
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
  ///   sniffers: const [
  ///     EmailSniffer(),
  ///     LinkSniffer(),
  ///     CustomSnifferType(), // Use it
  ///   ],
  /// )
  ///```
  final List<Sniffer> sniffers;

  /// The list of entries corresponding to each match in the text.
  ///
  /// This list is used in combination with the [onTapMatch] callback to provide
  /// additional data for each match. For example, if the text contains links, the
  /// entries in this list could be the URLs associated with those links.
  ///
  /// The length of this list should match the number of detected matches.
  final List<T> matchEntries;

  /// An optional callback that resolves the entry for each match.
  ///
  /// When provided, it takes precedence over [matchEntries] and is used to look
  /// up the value passed to [onTapMatch] and [matchBuilder]. Prefer this when
  /// your entries are keyed by matched text/type instead of by position, which
  /// is far more robust than keeping a positional list in sync with the text.
  ///
  /// ```dart
  /// TextSniffer<String>(
  ///   text: "Ask Alice or the Rabbit",
  ///   sniffers: [CharacterSnifferType()],
  ///   entryResolver: (matchText, type, index) => glossary[matchText],
  /// )
  /// ```
  final EntryResolver<T>? entryResolver;

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
  ///   onTapMatch: (link, match, type, index) {
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

  /// A callback function that is triggered when a matching part of the text is
  /// long-pressed.
  ///
  /// Receives the same arguments as [onTapMatch]. Typical use: copying a phone
  /// number or link to the clipboard, or showing a context menu.
  ///
  /// When a long press fires, the subsequent tap for that gesture is
  /// suppressed, so [onTapMatch] is not also called.
  final OnTapMatch<T>? onLongPressMatch;

  /// A callback function that is triggered when an error occurs during a tap
  /// or long-press action.
  ///
  /// If [onTapMatch] or [onLongPressMatch] throws an error, this callback will
  /// catch and handle it. If not provided, the error will be rethrown.
  final void Function(Object error, StackTrace stackTrace)? onError;

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

  /// Creates a [TextSniffer].
  const TextSniffer({
    super.key,
    required this.text,
    this.sniffers = const [],
    this.textStyle,
    this.semanticsLabel,
    this.locale,
    this.selectionColor,
    this.textScaler,
    this.selectionRegistrar,
    this.strutStyle,
    this.softWrap = true,
    this.textDirection,
    this.textHeightBehavior,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.onTapMatch,
    this.onLongPressMatch,
    this.onError,
    this.textWidthBasis = TextWidthBasis.parent,
    this.matchBuilder,
    this.matchEntries = const [],
    this.entryResolver,
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

  /// One reusable recognizer per matched segment, keyed by match index.
  ///
  /// Recognizers hold resources and must be disposed. They are created lazily,
  /// reused across rebuilds, and their handlers read [widget] at event time,
  /// so changing [TextSniffer.onTapMatch]/[TextSniffer.matchEntries] does not
  /// require re-parsing or recreating them.
  final Map<int, _TapAndLongPressRecognizer> _recognizers = {};

  /// The match index currently under the mouse pointer, if its sniffer has a
  /// [Sniffer.hoverStyle]; used to apply the hover style on web/desktop.
  int? _hoveredIndex;

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
    if (oldWidget.text != widget.text ||
        _signatureOf(widget.sniffers) != _patternSignature) {
      _parse();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers.values) {
      r.dispose();
    }
    _recognizers.clear();
  }

  String _signatureOf(List<Sniffer> types) =>
      types.map((e) => '${e.runtimeType}:${e.pattern?.pattern}').join('|');

  /// Parses the text into matched/non-matched segments.
  void _parse() {
    _disposeRecognizers();
    _hoveredIndex = null;
    _patternSignature = _signatureOf(widget.sniffers);
    _segments = _parseSegments(widget.text, widget.sniffers);
  }

  /// Handles a tap on a matched segment, reading the current widget so that the
  /// latest [TextSniffer.onTapMatch]/[TextSniffer.matchEntries] are always used.
  ///
  /// [matchEntries] is optional and per-match: an entry may simply not exist for
  /// the tapped match. In that case the callback receives a null entry, so
  /// [matchText]/[type]/[index] are always usable.
  void _handleTap(String matchText, Sniffer type, int index) {
    _invoke(widget.onTapMatch, matchText, type, index);
  }

  /// Handles a long press on a matched segment. Returns whether the event was
  /// consumed, i.e. whether [TextSniffer.onLongPressMatch] is set: when it is
  /// not, the gesture must still resolve as a regular tap.
  bool _handleLongPress(String matchText, Sniffer type, int index) {
    if (widget.onLongPressMatch == null) return false;
    _invoke(widget.onLongPressMatch, matchText, type, index);
    return true;
  }

  /// Invokes [callback] with the resolved entry, routing errors to
  /// [TextSniffer.onError] (or rethrowing when it is not provided).
  void _invoke(
      OnTapMatch<T>? callback, String matchText, Sniffer type, int index) {
    try {
      callback?.call(_entryFor(matchText, type, index), matchText, type, index);
    } catch (e, stack) {
      if (widget.onError != null) {
        widget.onError!(e, stack);
      } else {
        rethrow;
      }
    }
  }

  /// Resolves the entry for a match, preferring [TextSniffer.entryResolver]
  /// (keyed by the matched text/type) and falling back to positional
  /// [TextSniffer.matchEntries].
  T? _entryFor(String matchText, Sniffer type, int index) {
    final resolver = widget.entryResolver;
    if (resolver != null) return resolver(matchText, type, index);
    final entries = widget.matchEntries;
    return (index >= 0 && index < entries.length) ? entries[index] : null;
  }

  /// Returns a reusable recognizer for the match at [index], creating it once.
  ///
  /// Handlers are bound once per parse; they capture the segment's own
  /// [matchText]/[type] and read the current [widget] at event time.
  _TapAndLongPressRecognizer _recognizerFor(
      String matchText, Sniffer type, int index) {
    return _recognizers.putIfAbsent(index, () {
      final recognizer = _TapAndLongPressRecognizer();
      recognizer.onTap = () => _handleTap(matchText, type, index);
      recognizer.onLongPressMatch =
          () => _handleLongPress(matchText, type, index);
      return recognizer;
    });
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
        final entry = _entryFor(segment.text, type, index);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Semantics(
            button: true,
            child: GestureDetector(
              onTap: () => _handleTap(segment.text, type, index),
              onLongPress: widget.onLongPressMatch == null
                  ? null
                  : () => _handleLongPress(segment.text, type, index),
              child: widget.matchBuilder!(segment.text, index, type, entry),
            ),
          ),
        ));
        continue;
      }

      final hoverStyle = type.hoverStyle;
      final style = (hoverStyle != null && _hoveredIndex == index)
          ? (type.style ?? const TextStyle()).merge(hoverStyle)
          : type.style;

      spans.add(TextSpan(
        text: segment.text,
        style: style,
        // Show a clickable cursor on web/desktop; harmless on touch platforms.
        mouseCursor: SystemMouseCursors.click,
        onEnter: hoverStyle == null
            ? null
            : (_) => setState(() => _hoveredIndex = index),
        onExit: hoverStyle == null
            ? null
            : (_) => setState(() => _hoveredIndex = null),
        recognizer: _recognizerFor(segment.text, type, index),
      ));
    }

    final registrar =
        widget.selectionRegistrar ?? SelectionContainer.maybeOf(context);

    return RichText(
      textAlign: widget.textAlign,
      locale: widget.locale,
      selectionColor: registrar == null
          ? widget.selectionColor
          : widget.selectionColor ??
              DefaultSelectionStyle.of(context).selectionColor ??
              DefaultSelectionStyle.defaultColor,
      selectionRegistrar: registrar,
      softWrap: widget.softWrap,
      strutStyle: widget.strutStyle,
      textDirection: widget.textDirection,
      textHeightBehavior: widget.textHeightBehavior,
      textScaler: widget.textScaler ??
          MediaQuery.maybeTextScalerOf(context) ??
          TextScaler.noScaling,
      textWidthBasis: widget.textWidthBasis,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      text: TextSpan(children: spans, semanticsLabel: widget.semanticsLabel),
    );
  }
}

/// A [TapGestureRecognizer] that additionally reports long presses without
/// giving up the tap: [TextSpan.recognizer] accepts only a single recognizer,
/// so tap and long-press must be handled by one object.
///
/// A timer started on tap-down fires [onLongPressMatch] after
/// [kLongPressTimeout]; if the handler consumed the event (returned true), the
/// tap for that gesture is suppressed.
class _TapAndLongPressRecognizer extends TapGestureRecognizer {
  /// Called when the pointer has been held down past [kLongPressTimeout].
  /// Returns whether the long press was consumed; when false, the gesture
  /// still resolves as a regular tap on release.
  bool Function()? onLongPressMatch;

  Timer? _timer;
  bool _longPressConsumed = false;

  @override
  void handleTapDown({required PointerDownEvent down}) {
    _longPressConsumed = false;
    _timer = Timer(kLongPressTimeout, () {
      _longPressConsumed = onLongPressMatch?.call() ?? false;
    });
    super.handleTapDown(down: down);
  }

  @override
  void handleTapUp(
      {required PointerDownEvent down, required PointerUpEvent up}) {
    _timer?.cancel();
    if (!_longPressConsumed) {
      super.handleTapUp(down: down, up: up);
    }
  }

  @override
  void handleTapCancel(
      {required PointerDownEvent down,
      PointerCancelEvent? cancel,
      required String reason}) {
    _timer?.cancel();
    super.handleTapCancel(down: down, cancel: cancel, reason: reason);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// A single piece of the parsed text: either a matched or a non-matched run.
class _Segment {
  final String text;
  final bool isMatch;

  /// Zero-based position across all matches; valid only when [isMatch] is true.
  final int matchIndex;

  /// The sniffer type that produced this match; non-null only when [isMatch].
  final Sniffer? type;

  const _Segment.match(this.text, this.matchIndex, this.type) : isMatch = true;
  const _Segment.nonMatch(this.text)
      : isMatch = false,
        matchIndex = -1,
        type = null;
}

/// A single regex hit before overlap resolution: it knows the full span it
/// occupies in the source text, the text to display, its [Sniffer], and the
/// priority of that type (its position in the `sniffers` list).
class _RawMatch {
  /// Start offset of the full match in the source text (inclusive).
  final int start;

  /// End offset of the full match in the source text (exclusive).
  final int end;

  /// The text to display for this match (may be an inner capture group).
  final String text;

  final Sniffer type;

  /// Lower means higher priority; equals the type's index in `sniffers`.
  final int priority;

  _RawMatch(this.start, this.end, this.text, this.type, this.priority);
}

/// Splits [text] into matched/non-matched segments.
///
/// Each [Sniffer] is matched with its **own** regex (so each pattern keeps
/// its own flags, e.g. case sensitivity — nothing is forced case-insensitive).
/// When two matches overlap, the one whose type comes first in [sniffers]
/// wins, giving callers explicit control over priority. This is the only place
/// the regexes run over the full text, so it is the work callers cache (see
/// [_TextSnifferState._parse]).
List<_Segment> _parseSegments(String text, List<Sniffer> sniffers) {
  final raw = <_RawMatch>[];

  for (int priority = 0; priority < sniffers.length; priority++) {
    final type = sniffers[priority];
    final pattern = type.pattern;
    if (pattern == null || pattern.pattern.isEmpty) continue;

    final regex = RegexCache.get(pattern);
    for (final match in regex.allMatches(text)) {
      if (match.end == match.start) continue; // skip empty matches

      String matchedText = match[0] ?? '';
      // Links/emails display their whole match; other types can expose an inner
      // capture group as the display text (e.g. `[word]` -> `word`).
      if (type is! LinkSniffer && type is! EmailSniffer) {
        for (int i = 1; i <= match.groupCount; i++) {
          if (match[i] != null && match[i]!.isNotEmpty) {
            matchedText = match[i]!;
            break;
          }
        }
      }

      raw.add(_RawMatch(match.start, match.end, matchedText, type, priority));
    }
  }

  // Order by position, then by priority (earlier type wins), then longer first.
  raw.sort((a, b) {
    if (a.start != b.start) return a.start - b.start;
    if (a.priority != b.priority) return a.priority - b.priority;
    return (b.end - b.start) - (a.end - a.start); // coverage:ignore-line
  });

  final result = <_Segment>[];
  int currentIndex = 0;
  int matchIndex = 0;

  for (final match in raw) {
    // Skip anything overlapping a match we already committed to.
    if (match.start < currentIndex) continue;

    if (match.start > currentIndex) {
      result.add(_Segment.nonMatch(text.substring(currentIndex, match.start)));
    }

    result.add(_Segment.match(match.text, matchIndex, match.type));
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
  /// Maximum number of cached patterns; the oldest entry is evicted beyond
  /// this, so dynamically generated patterns cannot grow the cache unbounded.
  static const int maxEntries = 128;

  static final Map<String, RegExp> _cache = {};

  /// The number of patterns currently cached; never exceeds [maxEntries].
  static int get size => _cache.length;

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
    final cached = _cache[key];
    if (cached != null) return cached;
    if (_cache.length >= maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return _cache[key] = pattern;
  }
}
