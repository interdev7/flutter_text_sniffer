import 'package:flutter/material.dart';
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';
import 'package:flutter_text_sniffer_example/snack.dart';

class DefaultTextSniffer extends StatelessWidget {
  const DefaultTextSniffer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Default text sniffer"),
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: TextSniffer<String>(
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
            onTapMatch: (link, match, type, index, error) {
              if (error == null) {
                showSnackBar(context, link ?? "Not found");
              }
            },
          ),
        ),
      ),
    );
  }
}
