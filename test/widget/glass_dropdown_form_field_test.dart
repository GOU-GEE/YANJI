import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/design/glass/glass_dropdown_form_field.dart';

void main() {
  testWidgets('anchored glass menu selects a value and field rebounds', (
    tester,
  ) async {
    String? chosen = '数学';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: GlassDropdownFormField<String>(
                key: const Key('test-dropdown'),
                initialValue: chosen,
                decoration: const InputDecoration(labelText: '学习科目'),
                items: const [
                  DropdownMenuItem(value: '数学', child: Text('数学')),
                  DropdownMenuItem(value: '英语', child: Text('英语')),
                ],
                onChanged: (value) => chosen = value,
              ),
            ),
          ),
        ),
      ),
    );
    final field = find.byKey(const Key('test-dropdown'));
    final drag = await tester.startGesture(tester.getCenter(field));
    await drag.moveBy(const Offset(24, -8));
    await tester.pump();
    expect(
      tester
          .widget<Transform>(find.byKey(const Key('glass-elastic-transform')))
          .transform
          .entry(0, 3),
      greaterThan(0),
    );
    await drag.cancel();
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('glass-dropdown-dismiss')), findsOneWidget);
    await tester.tap(find.text('英语').last);
    await tester.pumpAndSettle();
    expect(chosen, '英语');
    expect(find.byKey(const Key('glass-dropdown-dismiss')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
