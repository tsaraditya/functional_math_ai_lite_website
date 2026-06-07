import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:functional_math_ai/main.dart'; // Make sure this matches your project name

void main() {
  testWidgets('AI Chat UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our initial placeholder text is displayed.
    expect(
      find.text('Type something below to query TinyLlama!'),
      findsOneWidget,
    );

    // Verify that the send button (IconButton) exists.
    expect(find.byIcon(Icons.send), findsOneWidget);

    // Verify that the input text field exists.
    expect(find.byType(TextField), findsOneWidget);
  });
}
