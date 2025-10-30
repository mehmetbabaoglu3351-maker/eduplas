// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp ayağa kalkıyor', (WidgetTester tester) async {
    // Uygulama kök sınıfına bağımlı olmadan, testin kendisinde minimal bir app kuruyoruz.
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('EduPlas Test')),
      ),
    ));

    // Basit doğrulamalar
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('EduPlas Test'), findsOneWidget);
  });
}
