import 'package:flutter_test/flutter_test.dart';
import 'package:yanji/core/ids/entity_ids.dart';

void main() {
  test('entity IDs have UUIDv7 version and RFC variant bits', () {
    final ids = EntityIds();
    final values = List.generate(2000, (_) => ids.next());
    final format = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(values.every(format.hasMatch), isTrue);
    expect(values.toSet().length, values.length);
  });

  test(
    'review dates are deterministic and reject normalized invalid dates',
    () {
      final ids = EntityIds();
      expect(
        ids.dailyReview(workspaceId: 'w', year: 2026, month: 9, day: 3),
        'daily_review/w/2026-09-03',
      );
      expect(
        ids.dailyReview(workspaceId: 'other', year: 2026, month: 9, day: 3),
        'daily_review/other/2026-09-03',
      );
      expect(
        ids.dailyReview(workspaceId: 'w', year: 2024, month: 2, day: 29),
        'daily_review/w/2024-02-29',
      );
      expect(
        () => ids.dailyReview(workspaceId: 'w', year: 2026, month: 2, day: 29),
        throwsArgumentError,
      );
      expect(
        () => ids.dailyReview(workspaceId: 'w', year: 2026, month: 13, day: 1),
        throwsArgumentError,
      );
    },
  );
}
