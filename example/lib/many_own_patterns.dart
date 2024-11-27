import 'package:flutter/material.dart';
import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';
import 'package:flutter_text_sniffer_example/snack.dart';

class ManyOwnPatterns extends StatelessWidget {
  const ManyOwnPatterns({super.key});

  @override
  Widget build(BuildContext context) {
    String text = "Email: example@domain.com or visit our [website]";

    // Combine regex for both email and text inside square brackets
    RegExp combinedRegex = RegExp(r"(?:[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})|\[(.*?)\]");

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Many own patterns"),
      ),
      body: Center(
        child: TextSniffer<String>(
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
          onTapMatch: (email, index, error) {
            if (error == null) {
              showSnackBar(context, email ?? "Not found");
            }
          },
        ),
      ),
    );
  }
}
