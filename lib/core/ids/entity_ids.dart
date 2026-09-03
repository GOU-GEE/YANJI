import 'package:uuid/uuid.dart';

/// IDs identify entities; HLC (not UUID ordering) resolves concurrent changes.
final class EntityIds {
  EntityIds({Uuid? uuid, this.generate}) : _uuid = uuid ?? const Uuid();
  final Uuid _uuid;

  /// Optional deterministic source for replay tests; production defaults to UUIDv7.
  final String Function()? generate;

  String next() => generate?.call() ?? _uuid.v7();

  /// The caller supplies a calendar date, never a UTC-converted instant.
  /// Workspace is part of the globally unique deterministic ID.
  String dailyReview({
    required String workspaceId,
    required int year,
    required int month,
    required int day,
  }) {
    if (workspaceId.isEmpty || workspaceId.contains('/')) {
      throw ArgumentError('Invalid workspace ID');
    }
    final date = DateTime.utc(year, month, day);
    if (year < 1 ||
        year > 9999 ||
        date.year != year ||
        date.month != month ||
        date.day != day) {
      throw ArgumentError('Invalid calendar date');
    }
    return 'daily_review/$workspaceId/${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }
}
