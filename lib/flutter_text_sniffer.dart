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
  final String ownPattern;

  /// The maximum number of lines for the text before it gets truncated.
  ///
  /// Defaults to 2. If the text exceeds this number of lines, it will be truncated
  /// with an ellipsis (`...`).
  final int maxLines;

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
  final void Function(T? entry, int index, Object? error)? onTapMatch;

  /// A custom builder function for creating the [TextSpan] for each match.
  ///
  /// This function allows you to define how each matching part of the text should be
  /// displayed and interacted with. If provided, it will override the default
  /// behavior and style for matches.
  ///
  /// - [match]: The string that matched the pattern.
  /// - [index]: The index of the match within the text.
  final Widget Function(String match, int index, T matchEntry)? matchBuilder;

  TextSniffer({
    super.key,
    required this.text,
    this.ownPattern = r'\[(.*?)\]',
    this.matchTextStyle,
    this.textStyle,
    this.textAlign,
    this.maxLines = 2,
    this.onTapMatch,
    this.matchBuilder,
    this.matchEntries = const [],
  }) : assert(
          RegExp(ownPattern).allMatches(text).length == matchEntries.length,
          "The number of matches must match the number of items in matchEntries",
        );

  void onTapMatchFn(List<T> matchEntries, int index) {
    if (matchEntries.isNotEmpty) {
      try {
        onTapMatch?.call(matchEntries[index], index, null);
      } catch (e, s) {
        onTapMatch?.call(null, index, e);
        if (kDebugMode) {
          debugPrint("Exception:\n$e\nStack trace: \n$s");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Split the text and process each part
    final spans = text.customSplitMapJoin<InlineSpan>(
      pattern: RegExp(ownPattern),
      onMatch: (text, index, count) {
        // If a custom matchBuilder is provided, use it
        if (matchBuilder != null) {
          return WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => onTapMatchFn(matchEntries, index),
              child: matchBuilder!(text, index, matchEntries[index]),
            ),
          );
        }
        return TextSpan(
          text: text,
          style: matchTextStyle,
          recognizer: TapGestureRecognizer()..onTap = () => onTapMatchFn(matchEntries, index),
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
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }
}

typedef _MatchCallback<T> = T Function(String text, int index, int matchCount);
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
  List<T> customSplitMapJoin<T>({
    required RegExp pattern,
    required _MatchCallback<T> onMatch,
    required _NonMatchCallback<T> onNonMatch,
  }) {
    List<T> result = [];
    int currentIndex = 0;
    int matchIndex = 0; // Index of the current match
    final matchCount = pattern.allMatches(this).length;
    for (var match in pattern.allMatches(this)) {
      // Add the part of the string before the match
      if (match.start > currentIndex) {
        result.add(onNonMatch(substring(currentIndex, match.start)));
      }
      // Safely access matched groups
      String matchedText = "";

      for (var i = 0; i < matchCount; i++) {
        if (match[i] != null) {
          final matches = match.pattern.allMatches(match[i]!);
          if (matches.isNotEmpty) {
            matchedText = matches.last[i]!;
          } else {
            matchedText = match[i]!;
          }
        }
      }
      // Add the processed match with its index
      result.add(onMatch(
        matchedText,
        matchIndex,
        matchCount,
      ));

      // Update the current index
      currentIndex = match.end;
      matchIndex++;
    }

    // Add the remaining part of the string after the last match
    if (currentIndex < length) {
      result.add(onNonMatch(substring(currentIndex)));
    }

    return result;
  }
}
