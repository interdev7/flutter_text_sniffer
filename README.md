# TextSniffer

[![pub package](https://img.shields.io/pub/v/flutter_text_sniffer.svg)](https://pub.dev/packages/flutter_text_sniffer)
[![CI/CD](https://github.com/interdev7/flutter_text_sniffer/actions/workflows/ci.yml/badge.svg)](https://github.com/interdev7/flutter_text_sniffer/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/interdev7/flutter_text_sniffer/branch/main/graph/badge.svg)](https://codecov.io/gh/interdev7/flutter_text_sniffer)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

![text_sniffer](https://github.com/user-attachments/assets/f9a6264e-863a-486f-91e4-fa9d2292f0a9)

`TextSniffer` is a powerful Flutter widget designed to detect and interact with specific text patterns. It allows developers to define custom patterns using regular expressions, apply unique styles to detected text, and handle user interactions such as taps on links or specific words.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Custom Builder](#custom-builder)
- [Defining Custom sniffers](#defining-custom-patterns)
- [Handling Taps & matchEntries](#handling-taps--matchentries)
- [Built-in Sniffers](#built-in-sniffers)
- [Long Press & Hover](#long-press--hover)
- [Selection](#selection)
- [Large Texts (books, articles)](#large-texts-books-articles)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Customizable Patterns**: Use regular expressions to define text patterns.
- **Interactive Text**: Make text segments respond to taps and long presses.
- **Styling Options**: Apply styles to both matching and non-matching text, plus hover styles on web/desktop.
- **Custom Match Builders**: Define how detected patterns appear.
- **Built-in Sniffers**: `EmailSniffer`, `LinkSniffer`, `PhoneSniffer`, `HashtagSniffer`, `MentionSniffer` — or create your own.
- **Individual Styling**: Style different types of matches individually.
- **Accessible by default**: respects the system font-size setting, exposes matches to screen readers, and works inside `SelectionArea`.

## Installation

To use `TextSniffer`, add the following to your `pubspec.yaml`:

```dart
dependencies:
  flutter_text_sniffer: ^latest_version
```

Then, run `flutter pub get` to install the package.

## Usage

### Basic Example

Here’s a simple example of how to use the `TextSniffer` widget:

```dart
TextSniffer(
   text: "Contact us at support@example.com or visit https://example.com/product?name=iPhone",
   sniffers: [
    // They are built in sniffers
     EmailSniffer(),
     LinkSniffer(),
   ],
   onTapMatch: (match, matchText, type, index) {
     print('Tapped on: $matchText');
   },
)
```

<img width="200" alt="image" src="https://github.com/user-attachments/assets/c9c6f7b1-069f-4a8c-80a1-ad65735957ef">

## Custom Builder

To customize how matched text is displayed, use the `matchBuilder` property:

```dart
final images = <String>[
  "assets/flutter.png",
  "assets/google.png",
];

class CustomSnifferType extends Sniffer {
  @override
  RegExp get pattern => RegExp(r'\[(.*?)\]');

  @override
  TextStyle? get style => const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold);

  @override
  String toString() => 'custom';
}

TextSniffer<String>(
  text: "Check out [Flutter] and [Google]!",
  matchEntries: const ['https://flutter.dev', 'https://google.com'],
  sniffers: [
    CustomSnifferType(),
  ],
  onTapMatch: (entry, match, type, index) {
    showSnackBar(context, entry ?? "Not found");
  },
  matchBuilder: (match, index, type, entry) {
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
            match,
            style: type.style,
          ),
        ],
      ),
    );
  },
)
```

<img width="200" alt="image" src="https://github.com/user-attachments/assets/2492ed6c-7c50-4617-96f6-0926ccb077dc">

## Defining Custom Patterns

You can define custom patterns using regular expressions. For example, to detect IP addresses, hashtag and custom:

```dart
// Custom sniffer. For example: [Example] => word in brackets => Example
class CustomSnifferType extends Sniffer {
  @override
  RegExp get pattern => RegExp(r'\[(.*?)\]');

  @override
  TextStyle? get style => const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold);

  @override
  String toString() => 'custom';
}

// IP address sniffer
class IpAddressSnifferType extends Sniffer {
  @override
  RegExp get pattern => RegExp(r'\b' // Start of word (word borders)
      r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' // 1 octet
      r'\.' // Dot
      r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' // 2 octet
      r'\.' // Dot
      r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' // 3 octet
      r'\.' // Dot
      r'(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)' // 4 octet
      r'\b' // End of word
      );

  @override
  TextStyle? get style => const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic);

  @override
  String toString() => 'ip_address';
}

// Hashtag sniffer
class HashtagSnifferType extends Sniffer {
  @override
  RegExp get pattern => RegExp(r'\B#\w\w+');

  @override
  TextStyle? get style => const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold);

  @override
  String toString() => 'hashtag';
}

TextSniffer(
  text: "Check out [Flutter] and [Google]!\nCheck out #Flutter and #Google! IP addresses: 192.168.0.1, 192.168.0.124",
  sniffers: [
    CustomSnifferType(),
    HashtagSnifferType(),
    IpAddressSnifferType(),
  ],
  matchEntries: const [
    'https://flutter.dev',
    'https://google.com',
  ],
  onTapMatch: (entry, matchText, type, index) {
    print('Tapped on: $matchText');
  },
)
```

<img width="200" alt="image" src="https://github.com/user-attachments/assets/d5a97bff-a10e-4098-aeca-ad8e5d438c1a">

## Handling Taps & matchEntries

`onTapMatch` is called whenever a matched segment is tapped:

```dart
onTapMatch: (entry, matchText, type, index) { ... }
```

- **`matchText`**, **`type`** and **`index`** are always provided — `index` is the
  zero-based position across **all** matches in the text (not per type), so use
  `type` to tell match kinds apart.
- **`entry`** is the item from `matchEntries` for this match, or `null` if you did
  not supply one. `matchEntries` is fully **optional** and **per-match**: provide
  it only when you need extra data (e.g. a URL behind a `[label]`). Mixing types
  where only some need entries is fine — taps on the others simply get `entry: null`.

### Error Handling

If an error is thrown inside `onTapMatch`, you can catch and handle it using the `onError` callback:

```dart
TextSniffer(
  text: "Contact us at support@example.com",
  sniffers: [EmailSniffer()],
  onTapMatch: (match, matchText, type, index) {
    throw Exception("Failed to handle tap");
  },
  onError: (error, stackTrace) {
    print("Caught error: $error");
  },
)
```

If `onError` is not provided, the error will be rethrown.

```dart
// Optional: attach data to specific matches.
TextSniffer<String>(
  text: "Visit [Flutter] or [Google]",
  sniffers: [CustomSnifferType()],
  matchEntries: const ['https://flutter.dev', 'https://google.com'],
  onTapMatch: (url, matchText, type, index) {
    // url == 'https://google.com' when "[Google]" is tapped
  },
)
```

## Built-in Sniffers

| Sniffer | Matches | Example |
|---|---|---|
| `EmailSniffer` | email addresses | `user@example.com` |
| `LinkSniffer` | URLs with a scheme or `www.` prefix | `https://flutter.dev`, `www.example.com` |
| `PhoneSniffer` | phone numbers | `+1 (555) 123-4567` |
| `HashtagSniffer` | hashtags (unicode-aware) | `#flutter` |
| `MentionSniffer` | @-mentions | `@flutterdev` |

By default `LinkSniffer` ignores bare hosts like `example.com` to avoid false
positives. If you want the older permissive matching, opt in with:

```dart
LinkSniffer(pattern: LinkSniffer.loosePattern)
```

## Long Press & Hover

Long presses are reported via `onLongPressMatch` (same signature as
`onTapMatch`); when a long press fires, the tap for that gesture is suppressed.
Every built-in sniffer also accepts a `hoverStyle`, merged into the match style
while the mouse hovers over it (web/desktop):

```dart
TextSniffer(
  text: "Call +1 (555) 123-4567",
  sniffers: [
    PhoneSniffer(
      hoverStyle: const TextStyle(decoration: TextDecoration.underline),
    ),
  ],
  onLongPressMatch: (entry, matchText, type, index) {
    Clipboard.setData(ClipboardData(text: matchText));
  },
)
```

## Selection

Wrap `TextSniffer` in a [`SelectionArea`](https://api.flutter.dev/flutter/material/SelectionArea-class.html)
and the text becomes selectable automatically — no `selectionRegistrar` wiring
needed. Use `selectionColor` to override the highlight color.

## Large Texts (books, articles)

`TextSniffer` renders a single `RichText`, and `RichText` lays out its **entire**
span tree eagerly. So do **not** put a whole book into one `TextSniffer` — split
the text into chunks (e.g. paragraphs) and render them lazily with
`ListView.builder`. Each chunk gets its own `TextSniffer`, so layout and pattern
matching only run for what is on screen:

```dart
ListView.builder(
  itemCount: paragraphs.length,
  itemBuilder: (context, index) => TextSniffer(
    text: paragraphs[index],
    sniffers: [EmailSniffer(), LinkSniffer()],
    onTapMatch: (entry, matchText, type, i) { /* ... */ },
  ),
)
```

Within each `TextSniffer`, parsing (running the regex) happens only when `text`
or `sniffers` change — not on every rebuild — so scrolling stays smooth.
See `example/lib/long_text_example.dart` for a runnable demo.

## Contributing

We welcome contributions! To contribute to `TextSniffer`, please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
