import 'package:flutter/material.dart';
import 'package:flutter_text_sniffer_example/custom_text_widgets.dart';
import 'package:flutter_text_sniffer_example/default_text_sniffer.dart';
import 'package:flutter_text_sniffer_example/many_own_patterns.dart';
import 'package:flutter_text_sniffer_example/own_pattern.dart';

void main() {
  runApp(
    const MaterialApp(
      home: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Text sniffer examples"),
        ),
        body: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const DefaultTextSniffer(),
                    ));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Default text sniffer"),
                      Icon(Icons.arrow_right),
                    ],
                  )),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const CustomTextWidget(),
                    ));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Custom text widgets"),
                      Icon(Icons.arrow_right),
                    ],
                  )),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const OwnPattern(),
                    ));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Own pattern"),
                      Icon(Icons.arrow_right),
                    ],
                  )),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ManyOwnPatterns(),
                    ));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Own many patterns"),
                      Icon(Icons.arrow_right),
                    ],
                  )),
            ],
          ),
        ));
  }
}
