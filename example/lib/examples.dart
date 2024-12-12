import 'package:flutter/material.dart';
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';
import 'package:flutter_text_sniffer/sniffer_types.dart';

// Custom sniffer. For example: [Example] => word in brackets => Example
class CustomSnifferType extends SnifferType {
  @override
  RegExp get pattern => RegExp(r'\[(.*?)\]');

  @override
  TextStyle? get style =>
      const TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold);

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
  TextStyle? get style =>
      const TextStyle(color: Colors.orange, fontStyle: FontStyle.italic);

  @override
  String toString() => 'ip_address';
}

// Hashtag sniffer
class HashtagSnifferType extends SnifferType {
  @override
  RegExp get pattern => RegExp(r'\B#\w\w+');

  @override
  TextStyle? get style =>
      const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold);

  @override
  String toString() => 'hashtag';
}

Widget title(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );

class TextSnifferExamples extends StatelessWidget {
  const TextSnifferExamples({super.key});

  @override
  Widget build(BuildContext context) {
    final images = <String>[
      "assets/flutter.png",
      "assets/google.png",
    ];
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: title("Text sniffer examples"),
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                title("Basic Example"),
                TextSniffer(
                  text:
                      "Contact us at support@example.com or \nvisit https://example.com/product?name=iPhone",
                  snifferTypes: [
                    EmailSnifferType(),
                    LinkSnifferType(),
                  ],
                  onTapMatch: (match, matchText, type, index, error) {
                    if (error == null) {
                      print('Tapped on: $matchText');
                    }
                  },
                )
              ],
            ),
            Column(
              children: [
                title("Custom Patterns"),
                TextSniffer(
                  text:
                      "Check out [Flutter] and [Google]!\nCheck out #Flutter and #Google! IP addresses: 192.168.0.1, 192.168.0.124",
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
              ],
            ),
            Column(
              children: [
                title("Custom builder"),
                TextSniffer(
                  text: "Long press to [Flutter] or [Google] for show tooltip",
                  snifferTypes: [
                    CustomSnifferType(),
                  ],
                  matchBuilder: (text, index, type, matchEntry) {
                    return Container(
                      padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                      child: Tooltip(
                        decoration: BoxDecoration(color: Colors.grey[500]),
                        richMessage:
                            WidgetSpan(child: Text(text, style: type.style)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (matchEntry != null)
                              Image.asset(
                                images[index],
                                width: 20,
                                height: 20,
                              ),
                            Text(
                              text,
                              style: type.style?.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  matchEntries: const [
                    'https://flutter.dev',
                    'https://google.com',
                  ],
                  onTapMatch: (match, matchText, type, index, error) {
                    if (error == null) {
                      print('Tapped on: $matchText');
                    }
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
