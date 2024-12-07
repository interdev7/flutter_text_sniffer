// ignore_for_file: public_member_api_docs, sort_constructors_first
library flutter_text_sniffer;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

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

  /// The style applied to the matching parts of the text.
  final TextStyle? matchTextStyle;

  /// A property that defines the styles applied to different match types found within the text.
  ///
  /// The `matchesTextStyle` object allows you to specify individual styles for each type of match,
  /// such as phone numbers, email addresses, URLs, and custom patterns. These styles are applied
  /// when their respective types are detected in the text.
  ///
  /// Available styles:
  /// - `phoneTextStyle`: Style for matched phone numbers.
  /// - `emailTextStyle`: Style for matched email addresses.
  /// - `linkTextStyle`: Style for matched URLs.
  /// - `customTextStyle`: Style for matched custom patterns (e.g., `[Flutter]`).
  ///
  /// Example:
  /// ```dart
  /// MatchesTextStyle matchesTextStyle = MatchesTextStyle(
  ///   phoneTextStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
  ///   emailTextStyle: TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
  ///   linkTextStyle: TextStyle(color: Colors.purple, decoration: TextDecoration.underline),
  ///   customTextStyle: TextStyle(color: Colors.orange),
  /// );
  ///
  /// TextSniffer(
  ///   text: "Call me at +1 800 555 0199 or email example@domain.com. Visit http://example.com",
  ///   matchesTextStyle: matchesTextStyle,
  ///   searchTypes: const [SearchType.phone, SearchType.email, SearchType.link],
  ///   textStyle: TextStyle(color: Colors.black),
  /// );
  /// ```
  ///
  /// Default behavior:
  /// If `matchesTextStyle` is not provided or a specific type is not styled, the `matchTextStyle`
  /// will be used as a fallback for the corresponding matches.
  final MatchesTextStyle? matchesTextStyle;

  /// A list of search types to apply for text matching.
  ///
  /// Each search type uses its own regular expression to find matches in the text.
  /// Available search types:
  ///
  /// - [SearchType.phone]: Matches phone numbers.
  /// - [SearchType.email]: Matches email addresses.
  /// - [SearchType.link]: Matches URLs.
  /// - [SearchType.custom]: Matches based on a custom regular expression,
  ///   provided through the [ownPattern] parameter.
  ///
  ///```dart
  /// final ownPattern = RegExp(r"\[(.*?)\]|(ABC)"); // For "Call me" and "ABC"
  ///
  /// TextSniffer(
  ///   text: "[Call me] at +1 800 555 0199 or email example@domain.com. Visit http://example.com. ABC",
  ///   maxLines: 2,
  ///   searchTypes: const [
  ///     SearchType.email,
  ///     SearchType.custom,
  ///     SearchType.link,
  ///     SearchType.phone,
  ///   ],
  ///   ownPattern: ownPattern,
  ///   textStyle: const TextStyle(
  ///       color: Colors.black,
  ///    ),
  ///   matchTextStyle: const TextStyle(
  ///       color: Colors.red,
  ///       fontWeight: FontWeight.bold,
  ///    ),
  /// )
  ///```
  ///
  /// If no search types are provided, the default regular expression is used,
  /// which looks for text inside square brackets (e.g., `[Flutter]`).
  final List<SearchType>? searchTypes;

  /// The list of entries corresponding to each match in the text.
  ///
  /// This list is used in combination with the [onTapMatch] callback to provide
  /// additional data for each match. For example, if the text contains links, the
  /// entries in this list could be the URLs associated with those links.
  ///
  /// The length of this list should match the number of detected matches.
  final List<T> matchEntries;

  /// Text alignment for the entire widget.
  ///
  /// Determines how the text is aligned within its container (e.g., left, right,
  /// center, etc.). Defaults to [TextAlign.start].
  final TextAlign? textAlign;

  /// How visual overflow should be handled.
  ///
  /// Default: `TextOverflow.ellipsis`
  final TextOverflow? overflow;

  /// A custom regular expression pattern used to find matches within the text.
  ///
  /// If this pattern is provided, it will override the default pattern, which looks
  /// for matches inside square brackets (e.g., `[Flutter]`). The custom pattern allows
  /// you to define your own rules for detecting parts of the text that need special
  /// styling or interactivity.
  ///
  /// Example:
  /// ```dart
  /// String text = "Email: example@domain.com or visit our website";
  /// // Combine regex for both email and text inside square brackets
  /// final ownPattern = RegExp(r"(?:[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})");
  ///
  /// TextSniffer<String>(
  ///   text: text,
  ///   ownPattern: ownPattern, // Custom pattern to find email addresses
  ///   matchEntries: ['mailto:example@domain.com'],
  ///   onTapMatch: (email, error) {
  ///     print('Tapped email: $email'); // Prints: mailto:example@domain.com
  ///   },
  /// )
  /// ```
  ///
  /// In this example, the custom pattern detects email addresses in the text,
  /// making them interactive. The default pattern of detecting text inside square
  /// brackets is replaced by the email detection logic.
  ///
  /// If no custom pattern is provided, the default pattern will be used.
  ///
  /// Default: `RegExp(r'\[(.*?)\]')`
  final RegExp? ownPattern;

  /// The maximum number of lines for the text before it gets truncated.
  ///
  /// If the text exceeds this number of lines, it will be truncated
  /// with an ellipsis (`...`).
  final int? maxLines;

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
  ///   onTapMatch: (link, error) {
  ///     print('Tapped link: $link');
  ///     // Open the link or perform an action
  ///   },
  /// )
  /// ```
  ///
  /// In this example, the words "Flutter" and "Google" will be rendered as interactive
  /// links. When tapped, the corresponding URL is printed.
  /// - [match]: The object of type [T] associated with the tapped match.
  final void Function(T? entry, String match, SearchType type, int index, Object? error)? onTapMatch;

  /// A custom builder function for creating the [TextSpan] for each match.
  ///
  /// This function allows you to define how each matching part of the text should be
  /// displayed and interacted with. If provided, it will override the default
  /// behavior and style for matches.
  ///
  /// - [match]: The string that matched the pattern.
  /// - [index]: The index of the match within the text.
  final Widget Function(String match, int index, SearchType type, T? matchEntry)? matchBuilder;

  const TextSniffer({
    super.key,
    required this.text,
    this.searchTypes,
    this.ownPattern,
    this.matchTextStyle,
    this.matchesTextStyle,
    this.textStyle,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.onTapMatch,
    this.matchBuilder,
    this.matchEntries = const [],
  });

  void onTapMatchFn(List<T> matchEntries, String match, SearchType type, int index) {
    try {
      onTapMatch?.call(matchEntries[index], match, type, index, null);
    } catch (e, s) {
      onTapMatch?.call(null, match, type, index, e);
      if (kDebugMode) {
        print("Exception:\n$e\nStack trace: \n$s");
      }
    }
  }

  Map<SearchType, RegExp> get _patternByType {
    return {
      SearchType.phone: RegExp(
        r'(\+?\d{1,3}[\s\(\)-]?)?(\(?\d{1,4}\)?[\s\(\)-]?\d{1,4}[\s\(\)-]?\d{1,4}[\s\(\)-]?\d{1,4}|\d{10})',
        caseSensitive: false,
      ),
      SearchType.email: RegExp(r'(?:[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'),
      SearchType.link: RegExp(
        r'((http|https|ftp|ftps|sftp|file|mailto|telnet|ssh|ws|wss|irc|rtsp|rtmp|sip|sms|tel):\/\/)?(www\.)?[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[^\s]*)?',
        caseSensitive: false,
      ),
      SearchType.custom: ownPattern ?? RegExp(r'\[(.*?)\]'),
    };
  }

  Map<SearchType, TextStyle?> get _matcheStyles {
    return {
      SearchType.phone: matchesTextStyle?.phoneTextStyle ?? matchTextStyle,
      SearchType.email: matchesTextStyle?.emailTextStyle ?? matchTextStyle,
      SearchType.link: matchesTextStyle?.linkTextStyle ?? matchTextStyle,
      SearchType.custom: matchesTextStyle?.customTextStyle ?? matchTextStyle,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Determine the pattern based on searchTypes
    RegExp combinedPattern;
    if (searchTypes != null && searchTypes!.isNotEmpty) {
      combinedPattern = RegExp(
        searchTypes!.map((e) => _patternByType[e]!.pattern).join('|'),
        caseSensitive: false,
      );
    } else {
      combinedPattern = _patternByType[SearchType.custom]!;
    }
    // Split the text and process each part
    final spans = text._customSplitMapJoin<InlineSpan>(
      pattern: combinedPattern,
      patternByType: _patternByType,
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
          style: _matcheStyles[type],
          recognizer: TapGestureRecognizer()..onTap = () => onTapMatchFn(matchEntries, text, type, index),
        );
      },
      onNonMatch: (nonMatch) {
        return TextSpan(
          text: nonMatch,
          style: textStyle,
        );
      },
    );

    return RichText(
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}

typedef _MatchCallback<T> = T Function(String text, int index, int matchCount, SearchType type);
typedef _NonMatchCallback<T> = T Function(String nonMatch);

/// Extension on the [String] class that provides a custom `splitMapJoin`
/// implementation.
///
/// This extension allows splitting a string based on a regular expression pattern,
/// processing the matched and non-matched parts, and then re-joining them into
/// a list of type [T].
extension on String {
  /// Splits the string using the provided [pattern], processes each matching
  /// and non-matching part, and returns a list of [T].
  ///
  /// - [onMatch]: A callback that processes each match and returns a value of type [T].
  /// - [onNonMatch]: A callback that processes each non-matching part and returns a value of type [T].
  ///
  /// Example:
  /// ```dart
  /// final result = "This [is] a [test]".customSplitMapJoin<TextSpan>(
  ///   pattern: RegExp(r'\[(.*?)\]'),
  ///   onMatch: (match, index) => TextSpan(text: match[1]!),
  ///   onNonMatch: (nonMatch) => TextSpan(text: nonMatch),
  /// );
  /// ```
  /// In this example, the string is split based on words inside square brackets, and
  /// each match is processed differently from the non-matching parts.
  List<T> _customSplitMapJoin<T>({
    required RegExp pattern,
    required _MatchCallback<T> onMatch,
    required _NonMatchCallback<T> onNonMatch,
    required Map<SearchType, RegExp> patternByType,
  }) {
    List<T> result = [];
    int currentIndex = 0;
    int matchIndex = 0;
    final matchCount = pattern.allMatches(this).length;

    for (var match in pattern.allMatches(this)) {
      if (match.start > currentIndex) {
        result.add(onNonMatch(substring(currentIndex, match.start)));
      }

      String matchedText = match[0] ?? '';

      for (var i = 0; i <= match.groupCount; i++) {
        final group = match.group(i);

        if (group != null && i == 1) {
          matchedText = group;
          break;
        }
      }

      SearchType? type;
      for (var entry in patternByType.entries) {
        if (entry.value.matchAsPrefix(matchedText) != null) {
          type = entry.key;
          break;
        }
      }
      type ??= SearchType.custom;

      result.add(onMatch(matchedText, matchIndex, matchCount, type));
      currentIndex = match.end;
      matchIndex++;
    }

    if (currentIndex < length) {
      result.add(onNonMatch(substring(currentIndex)));
    }

    return result;
  }
}

/// Enum to define search types with their associated regular expressions.
enum SearchType {
  /// Matches phone numbers.
  phone,

  /// Matches email addresses.
  email,

  /// Matches URLs.
  link,

  /// Matches using a custom regular expression.
  custom,
}

class MatchesTextStyle {
  final TextStyle? phoneTextStyle;
  final TextStyle? emailTextStyle;
  final TextStyle? linkTextStyle;
  final TextStyle? customTextStyle;
  MatchesTextStyle({
    this.phoneTextStyle,
    this.emailTextStyle,
    this.linkTextStyle,
    this.customTextStyle,
  });
}
