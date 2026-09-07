/// Admission year -> first day of the preliminary examination.
/// Verified Ministry of Education notices; future years remain estimates.
class ExamSchedule {
  static final _announced = <int, DateTime>{
    2024: DateTime.utc(2023, 12, 23),
    2025: DateTime.utc(2024, 12, 21),
    2026: DateTime.utc(2025, 12, 20),
  };

  static bool isAnnounced(int year) => _announced.containsKey(year);

  static DateTime dateFor(int year) {
    if (year < 2024 || year > 2100) throw ArgumentError.value(year, 'year');
    if (_announced.containsKey(year)) return _announced[year]!;
    // Product estimate only: Saturday on or after December 20 of prior year.
    final start = DateTime.utc(year - 1, 12, 20);
    return start.add(Duration(days: (DateTime.saturday - start.weekday) % 7));
  }

  static int? yearFromName(String? name) => int.tryParse(
    RegExp(r'\b(20\d{2}|2100)\s*考研').firstMatch(name ?? '')?.group(1) ?? '',
  );

  static int nextYear(DateTime today) {
    final day = DateTime.utc(today.year, today.month, today.day);
    return dateFor(today.year + 1).isBefore(day)
        ? today.year + 2
        : today.year + 1;
  }

  static bool isEstimate(int year, DateTime date) =>
      !isAnnounced(year) &&
      dateFor(year) == DateTime.utc(date.year, date.month, date.day);
}
