# TextSniffer

![text_sniffer](https://github.com/user-attachments/assets/f9a6264e-863a-486f-91e4-fa9d2292f0a9)

`TextSniffer` is a powerful Flutter widget designed to detect and interact with specific text patterns. It allows developers to define custom patterns using regular expressions, apply unique styles to detected text, and handle user interactions such as taps on links or specific words.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Custom Builder](#custom-builder)
- [Defining Custom sniffers](#defining-custom-patterns)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Customizable Patterns**: Use regular expressions to define text patterns.
- **Interactive Text**: Make text segments interactive, responding to user taps.
- **Styling Options**: Apply styles to both matching and non-matching text.
- **Custom Match Builders**: Define how detected patterns appear.
- **Multiple Search Sniffers**: Supports for emails and links by default but you can create own Sniffers.
- **Individual Styling**: Style different types of matches individually.

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
   snifferTypes: [
    // They are built in sniffers
     EmailSnifferType(), 
     LinkSnifferType(),
   ],
   onTapMatch: (match, matchText, type, index, error) {
     if (error == null) {
       print('Tapped on: $matchText');
     }
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

class CustomSnifferType extends SnifferType {
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
  snifferTypes: [
    CustomSnifferType(),
  ],
  onTapMatch: (entry, match, type, index, error) {
    if (error == null) {
      showSnackBar(context, entry ?? "Not found");
    }
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
class CustomSnifferType extends SnifferType {
  @override
  RegExp get pattern => RegExp(r'\[(.*?)\]');

  @override
  TextStyle? get style => const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold);

  @override
  String toString() => 'custom';
}

// IP address sniffer
class IpAddressSnifferType extends SnifferType {
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
class HashtagSnifferType extends SnifferType {
  @override
  RegExp get pattern => RegExp(r'\B#\w\w+');

  @override
  TextStyle? get style => const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold);

  @override
  String toString() => 'hashtag';
}

TextSniffer(
  text: "Check out [Flutter] and [Google]!\nCheck out #Flutter and #Google! IP addresses: 192.168.0.1, 192.168.0.124",
  snifferTypes: [
    CustomSnifferType(),
    HashtagSnifferType(),
    IpAddressSnifferType(),
  ],
  matchEntries: const [
    'https://flutter.dev',
    'https://google.com',
  ],
  onTapMatch: (entry, matchText, type, index, error) {
    if (error == null) {
      print('Tapped on: $matchText');
    }
  },
)
```

<img width="200" alt="image" src="https://github.com/user-attachments/assets/d5a97bff-a10e-4098-aeca-ad8e5d438c1a">

## Contributing

We welcome contributions! To contribute to `TextSniffer`, please follow these steps:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## License

This project is licensed under the BSD-3-Clause License. See the [LICENSE](LICENSE) file for more details.
