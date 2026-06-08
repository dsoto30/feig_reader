import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feig_reader/main.dart';

void main() {
  testWidgets('App renders FEIG Reader title', (WidgetTester tester) async {
    await tester.pumpWidget(const FeigReaderApp());
    expect(find.text('FEIG Reader'), findsWidgets);
  });

  testWidgets('IP and port fields are present', (WidgetTester tester) async {
    await tester.pumpWidget(const FeigReaderApp());
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
