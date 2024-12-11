# Flutter Text Sniffer

`flutter_text_sniffer` is a powerful and customizable Flutter library designed to detect specific patterns within a text and make them interactive. With this library, you can easily identify and handle text patterns such as emails, links, phone numbers, or custom patterns, and define specific styles or actions for each match.

## Features

- Detect multiple types of text patterns (e.g., email, link, phone number).
- Support for custom patterns using regular expressions.
- Apply custom styles to matched and unmatched text segments.
- Add interactivity to matches with tap callbacks.
- Custom widget builders for matched text segments.
- Fully customizable and supports a wide range of text styling options.

---

## Installation

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_text_sniffer: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Usage

### Basic Example

Here's a simple example of using `TextSniffer` to detect links and emails within a text:

```dart
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';
import 'package:flutter_text_sniffer/search_types.dart';

class MyTextSnifferWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextSniffer(
      text: "Contact us at support@example.com or visit https://flutter.dev",
      snifferTypes: const [
        EmailSnifferType(),
        LinkSnifferType(),
      ],
      onTapMatch: (match, matchText, type, index, error) {
        if (error == null) {
          print('Tapped on: $matchText');
        }
      },
      textStyle: TextStyle(color: Colors.black),
    );
  }
}
```

---

### Advanced Example with Custom Pattern

You can define custom patterns and styles as shown below:

```dart
class CustomSnifferType extends SnifferType {
  CustomSnifferType()
      : super(
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigoAccent),
          pattern: RegExp(r'\[(.*?)\]|(ABC)'),
        );

  @override
  String toString() => 'custom';
}

class AdvancedTextSnifferWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextSniffer(
      text: "[Email] example@domain.com. Visit http://example.com. ABC",
      snifferTypes: const [
        EmailSnifferType(),
        LinkSnifferType(),
        CustomSnifferType(),
      ],
      textStyle: const TextStyle(fontSize: 16),
      onTapMatch: (match, matchText, type, index, error) {
        print('Tapped match: $matchText, Type: $type');
      },
    );
  }
}
```

---

## API Reference

### `TextSniffer`

#### Parameters:

| Parameter            | Type                       | Description                                                                                  |
|----------------------|----------------------------|----------------------------------------------------------------------------------------------|
| `text`               | `String`                  | The full text to be displayed.                                                              |
| `snifferTypes`       | `List<SnifferType>`       | A list of sniffer types to detect patterns within the text.                                 |
| `textStyle`          | `TextStyle?`              | Style applied to non-matching text.                                                        |
| `onTapMatch`         | `OnTapMatch<T>?`          | Callback triggered when a matching part of the text is tapped.                              |
| `matchEntries`       | `List<T>`                 | List of entries corresponding to matches in the text. Used in combination with `onTapMatch`.|
| `matchBuilder`       | `MatchBuilder<T>?`        | Custom builder function for creating the widget for each match.                             |

#### Sniffer Types:

- `EmailSnifferType`: Detects email addresses.
- `LinkSnifferType`: Detects web links.

---

## Example

Create an interactive text that highlights and makes patterns actionable:

```dart
TextSniffer(
  text: "Call us at +123456789 or email contact@company.com",
  snifferTypes: const [
    PhoneSnifferType(),
    EmailSnifferType(),
  ],
  matchEntries: const [
    "+123456789",
    "contact@company.com",
  ],
  onTapMatch: (entry, matchText, type, index, error) {
    if (error == null) {
      print('User tapped on: $matchText');
    }
  },
);
```

---

## Contributing

Contributions are welcome! Please create an issue or submit a pull request for any enhancements, bug fixes, or suggestions.

---

## License

This library is released under the MIT License. See the LICENSE file for details.

