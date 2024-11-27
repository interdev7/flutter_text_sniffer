import 'package:flutter/material.dart';
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';
import 'package:flutter_text_sniffer_example/snack.dart';

class CustomTextWidget extends StatelessWidget {
  const CustomTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final images = <String>[
      "assets/flutter.png",
      "assets/google.png",
    ];
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Custom text widgets"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            ),
            const SizedBox(height: 25),
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
              matchBuilder: (text, index, entry) {
                return Container(
                  padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                  child: ElevatedButton.icon(
                    icon: Image.asset(
                      images[index],
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () {
                      showSnackBar(context, entry ?? "No entry");
                    },
                    label: Text(
                      text,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 63, 112, 211),
                        fontSize: 14,
                        height: 1.55,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            TextSniffer<Widget>(
              text: "Check out [Flutter] and [Google]!",
              matchEntries: const [
                Text(
                  'https://flutter.dev',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'https://google.com',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              textStyle: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 14,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
                height: 1.55,
              ),
              matchBuilder: (text, index, entry) {
                return entry ?? const Text("No entry");
              },
            ),
          ],
        ),
      ),
    );
  }
}
