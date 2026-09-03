import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/app/yanji_app.dart';

void main() {
  testWidgets('bootstrap works without network or platform storage', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: YanJiApp()));
    await tester.pumpAndSettle();
    expect(find.text('研迹'), findsOneWidget);
    expect(find.text('YanJi'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
