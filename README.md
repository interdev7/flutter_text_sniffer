# TextSniffer

`TextSniffer` is a Flutter widget that detects specific patterns within a text and makes them interactive. It allows you to define custom patterns using regular expressions, apply styles to detected parts, and handle user interactions like taps on links or specific words.

Content

- [Installation](#installation)
- [Usage](#usage)
- [Custom builder](#custom-builder)
- [Own Patterns](#own-patterns)
- [Max lines](#max-lines-example)

## Features

- Customizable text patterns using regular expressions.
- Interactive text segments that respond to user taps.
- Styling options for both matching and non-matching text.
- Support for custom match builders to define the appearance of detected patterns.
- Max line truncation with ellipsis for overflowing text.

## Installation

To use `TextSniffer`, add it to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_text_sniffer: ^1.0.0
```

## Usage

### Basic Example

Here’s a simple example of how to use the `TextSniffer` widget:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TextSniffer<String>(
            text: "Check out [Flutter] and [Google]!",
            matchEntries: ['https://flutter.dev', 'https://google.com'],
            onTapMatch: (link, index, error) {
              if(error == null){
                print('Tapped link: $link');
              }
            },
            textStyle: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 24,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              height: 1.55,
            ),
            matchTextStyle: const TextStyle(
              color: Color.fromARGB(255, 63, 112, 211),
              fontSize: 24,
              height: 1.55,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }
}
```

  <img width="200" alt="image" src="https://github.com/user-attachments/assets/09baabbf-07d6-496c-ba8f-a7a4a6a6f8bf">

## Custom builder

#### To customize how matched text is displayed, use the `matchBuilder` property:

```dart

final images = <String>[
      "assets/flutter.png",
      "assets/google.png",
    ];

TextSniffer<String>(
  text: "Check out [Flutter] and [Google]!",
  matchEntries: const ['https://flutter.dev', 'https://google.com'],
  textStyle: const TextStyle(
    color: Color(0xFF262626),
    fontSize: 14,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    height: 1.55,
  ),
  matchTextStyle: const TextStyle(
    color: Color.fromARGB(255, 63, 112, 211),
    fontSize: 14,
    height: 1.55,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
  ),
  onTapMatch: (link, index, error) {
    if (error == null) {
      showSnackBar(context, link ?? "Not found");
    }
  },
  matchBuilder: (text, index, entry) {
    return Container(
      padding: const EdgeInsets.only(left: 4.0, right: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            images[index],
            width: 20,
            height: 20,
          ),
          Text(
            text,
            style: const TextStyle(
              color: Color.fromARGB(255, 63, 112, 211),
              fontSize: 14,
              height: 1.55,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  },
)
```

  <img width="200" alt="image" src="https://github.com/user-attachments/assets/3a3299c0-6dfe-480f-82d1-c812dc1b58f3">

## IMPORTANT

> [!WARNING]
> If you use `matchBuilder`, you must be sure that the number of matches in the text matches the number of items in `matchEntries`, otherwise you will get an error: **_"The number of matches must match the number of items in matchEntries"_**

Example:

```dart

TextSniffer<String>(
  text: "Check out [Flutter] and [Google]!", // Two matches
  matchEntries: const ['https://flutter.dev'], // One element
  matchBuilder: (text, index, entry) => Text(text), // Here error!!!
)
```

## Own Patterns

You can define custom patterns using regular expressions. For example, to detect email addresses:

```dart
String text = "Email: example@domain.com or visit our website";

final ownPattern = RegExp(r"(?:[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})"); // Regex for email

TextSniffer<String>(
  text: text,
  ownPattern: ownPattern, // Custom pattern to find email addresses
  matchEntries: ['mailto:example@domain.com'],
  onTapMatch: (email, index, error) {
    if (error == null) {
      print('Tapped email: $email'); // Prints: mailto:example@domain.com
    }

  },
)
```

  <img width="200" alt="image" src="https://github.com/user-attachments/assets/e9a18f5b-00dd-41c1-a1a1-baffe31d56dc">

Also you can combine regex to find matches.

For example, if you need to find both an email and text in square brackets:

```dart
String text = "Email: example@domain.com or visit our [website]";

// Combine regex for both email and text inside square brackets
final combinedRegex = RegExp(r"(?:[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})|\[(.*?)\]");

TextSniffer<String>(
  text: text,
  ownPattern: combinedRegex, // Use it
  matchEntries: const [
            "mailto:example@gamil.com", // for clicking on email address
            "https://example.com", // for clicking on website
          ],
  textStyle: const TextStyle(
    color: Color(0xFF262626),
    fontSize: 14,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w400,
    height: 1.55,
  ),
  matchTextStyle: const TextStyle(
    color: Color.fromARGB(255, 63, 112, 211),
    fontSize: 14,
    height: 1.55,
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
  ),
  onTapMatch: (entry, index, error) {
    if (error == null) {
      print(entry); // Prints: mailto:example@domain.com or https://example.com
    }
  },
)
```

  <img width="200" alt="image" src="https://github.com/user-attachments/assets/ed2dd69e-44fb-4553-9526-39b8b45a627b">

## Max Lines Example

You can limit the number of lines the text can occupy:

```dart
TextSniffer<String>(
  text: "This is a long text that will be truncated if it exceeds two lines. Here is more text to ensure we exceed the limit.",
  matchEntries: [],
  maxLines: 2, // Limits to two lines
)
```
