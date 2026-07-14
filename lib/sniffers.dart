import 'package:flutter/material.dart';

/// An abstract class that defines the blueprint for text matching and styling.
///
/// This class is intended to be extended by specific implementations
/// that provide regular expressions for matching text patterns and
/// corresponding text styles for formatting the matched content.
abstract class Sniffer {
  /// Creates a sniffer with an optional [style], [hoverStyle] and [pattern].
  Sniffer({TextStyle? style, TextStyle? hoverStyle, RegExp? pattern})
      : _style = style,
        _hoverStyle = hoverStyle,
        _pattern = pattern;

  final TextStyle? _style;
  final TextStyle? _hoverStyle;
  final RegExp? _pattern;

  /// The style applied to text matched by this sniffer.
  TextStyle? get style => _style;

  /// The style merged into [style] while the pointer hovers over a match
  /// (web/desktop). When `null`, matches have no hover effect.
  TextStyle? get hoverStyle => _hoverStyle;

  /// The regular expression used to find matches. A `null` or empty pattern
  /// never matches.
  RegExp? get pattern => _pattern;
}

/// Matches email addresses.
/// Example: example@domain.com
class EmailSniffer extends Sniffer {
  /// Creates an email sniffer, optionally overriding the default [style],
  /// [hoverStyle] or [pattern].
  EmailSniffer({TextStyle? style, super.hoverStyle, RegExp? pattern})
      : super(
          style: style ??
              const TextStyle(
                  color: Colors.redAccent, fontStyle: FontStyle.italic),
          pattern: pattern ??
              RegExp(r'(?:[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})',
                  caseSensitive: false),
        );

  @override
  String toString() => 'email';
}

/// Matches URLs.
///
/// By default only unambiguous links are matched: those with an explicit
/// scheme (`https://…`, `ftp://…`, …) or starting with `www.`. This avoids
/// false positives on plain words like `example.com` or file names.
///
/// To restore the older permissive behavior (any `word.tld`-looking token),
/// pass [LinkSniffer.loosePattern] as the [pattern]:
///
/// ```dart
/// LinkSniffer(pattern: LinkSniffer.loosePattern)
/// ```
class LinkSniffer extends Sniffer {
  /// Creates a link sniffer, optionally overriding the default [style],
  /// [hoverStyle] or [pattern].
  LinkSniffer({TextStyle? style, super.hoverStyle, RegExp? pattern})
      : super(
          style: style ??
              const TextStyle(
                  color: Colors.blue, decoration: TextDecoration.underline),
          pattern: pattern ??
              RegExp(
                  r'((https?|ftps?|sftp|file|telnet|ssh|wss?|irc|rtsp|rtmp):\/\/[^\s<>()]+'
                  r'|www\.[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+(\/[^\s<>()]*)?)',
                  caseSensitive: false),
        );

  /// A permissive pattern that also matches scheme-less hosts such as
  /// `example.com`. Prone to false positives; opt in only if you need it.
  static final RegExp loosePattern = RegExp(
      r'((https?|ftps?|sftp|file|telnet|ssh|wss?|irc|rtsp|rtmp):\/\/)?(www\.)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(\/[^\s]*)?(\?[a-zA-Z0-9&=%_-]+)?',
      caseSensitive: false);

  @override
  String toString() => 'link';
}

/// Matches phone numbers.
/// Examples: +1 (555) 123-4567, 8-800-555-35-35, +49 30 901820
class PhoneSniffer extends Sniffer {
  /// Creates a phone sniffer, optionally overriding the default [style],
  /// [hoverStyle] or [pattern].
  PhoneSniffer({TextStyle? style, super.hoverStyle, RegExp? pattern})
      : super(
          style: style ?? const TextStyle(color: Colors.teal),
          pattern: pattern ??
              RegExp(
                  r'(?<!\w)\+?\d{1,3}[ .-]?(?:\(\d{1,4}\)[ .-]?)?\d{2,4}(?:[ .-]?\d{2,4}){1,3}(?!\w)'),
        );

  @override
  String toString() => 'phone';
}

/// Matches hashtags.
/// Examples: #flutter, #дартс, #dev_life
class HashtagSniffer extends Sniffer {
  /// Creates a hashtag sniffer, optionally overriding the default [style],
  /// [hoverStyle] or [pattern].
  HashtagSniffer({TextStyle? style, super.hoverStyle, RegExp? pattern})
      : super(
          style: style ??
              const TextStyle(
                  color: Colors.blueAccent, fontWeight: FontWeight.w600),
          pattern:
              pattern ?? RegExp(r'(?<![\w#])#[\p{L}\p{N}_]+', unicode: true),
        );

  @override
  String toString() => 'hashtag';
}

/// Matches @-mentions.
/// Examples: @flutterdev, @user_42
class MentionSniffer extends Sniffer {
  /// Creates a mention sniffer, optionally overriding the default [style],
  /// [hoverStyle] or [pattern].
  MentionSniffer({TextStyle? style, super.hoverStyle, RegExp? pattern})
      : super(
          style: style ??
              const TextStyle(
                  color: Colors.deepPurple, fontWeight: FontWeight.w600),
          pattern: pattern ?? RegExp(r'(?<![\w@])@[a-zA-Z0-9_]{2,}'),
        );

  @override
  String toString() => 'mention';
}
