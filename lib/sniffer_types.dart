import 'package:flutter/material.dart';

/// An abstract class that defines the blueprint for text matching and styling.
///
/// This class is intended to be extended by specific implementations
/// that provide regular expressions for matching text patterns and
/// corresponding text styles for formatting the matched content.
abstract class SnifferType {
  // Constructor to initialize style and pattern
  SnifferType({TextStyle? style, RegExp? pattern})
      : _style = style,
        _pattern = pattern;

  // Make style and pattern final and private
  final TextStyle? _style;
  final RegExp? _pattern;

  // Getters to access the style and pattern
  TextStyle? get style => _style;
  RegExp? get pattern => _pattern;
}

/// Matches email addresses.
/// Example: example@domain.com
class EmailSnifferType extends SnifferType {
  EmailSnifferType({TextStyle? style, RegExp? pattern})
      : super(
          style: style ?? const TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
          pattern: pattern ?? RegExp(r'(?:[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'),
        );

  @override
  String toString() => 'email';
}

/// Matches URLs with various protocols.
/// Examples: http://example.com, https://www.example.com
class LinkSnifferType extends SnifferType {
  LinkSnifferType({TextStyle? style, RegExp? pattern})
      : super(
          style: style ?? const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
          pattern:
              pattern ?? RegExp(r'((http|https|ftp|ftps|sftp|file|mailto|telnet|ssh|ws|wss|irc|rtsp|rtmp|sip|sms|tel):\/\/)?(www\.)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(\/[^\s]*)?(\?[a-zA-Z0-9&=%_-]+)?'),
        );

  @override
  String toString() => 'link';
}
