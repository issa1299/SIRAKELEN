import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sirakele/widgets/google_logo.dart';

void main() {
  testWidgets('logo se construit', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: GoogleLogo(size: 96))),
    ));
    expect(find.byType(GoogleLogo), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
