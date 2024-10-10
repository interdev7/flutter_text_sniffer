// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_text_sniffer/flutter_text_sniffer.dart';

// void main() {
//   testWidgets('TextSniffer uses custom ownPattern for matching', (WidgetTester tester) async {
//     // Define a variable to track the interaction
//     String tappedValue = '';

//     // Create test text
//     const String text = 'Email: [example@domain.com] or visit our website';

//     // Build the TextSniffer widget with a custom pattern to match emails
//     await tester.pumpWidget(
//       MaterialApp(
//         home: Scaffold(
//           body: TextSniffer<String>(
//             text: text,
//             ownPattern: RegExp(r'\[(.*?)\]'), // Pattern for emails
//             matchEntries: const ['mailto:example@domain.com'], // List of match entries
//             onTapMatch: (match) {
//               tappedValue = match; // Update value when tapped
//             },
//           ),
//         ),
//       ),
//     );

//     // Verify that the text is correctly displayed
//     expect(find.text('Email: example@domain.com or visit our website'), findsOneWidget);

//     // Access the RichText widget
//     final richTextWidget = tester.widget<RichText>(find.byType(RichText));

//     // Cast the root inline span as a TextSpan to access its children
//     final textSpan = richTextWidget.text as TextSpan;

//     // Find the part of the text that matches the email (child 1) and simulate a tap
//     final gestureRecognizer = textSpan.recognizer as TapGestureRecognizer?;

//     // Simulate a tap on the email
//     gestureRecognizer?.onTap!();

//     // Verify that the tapped value was updated when the email was clicked
//     expect(tappedValue, 'mailto:example@domain.com');
//   });
// }
