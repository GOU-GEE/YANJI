import '../core/database/app_database.dart' show Subject;

class TaskInputResult {
  const TaskInputResult(this.title, this.subjectId, this.minutes, this.message);
  final String title;
  final String? subjectId;
  final int? minutes;
  final String message;
}

/// Offline, conservative parsing: ambiguous subjects/durations remain editable.
class TaskInputParser {
  static const aliases = <String, List<String>>{
    '高等数学': ['高数'],
    '线性代数': ['线代'],
    '概率论与数理统计': ['概率论', '概率统计', '概率'],
    '计算机组成原理': ['计组', '组成原理'],
    '数据结构': ['数据结构'],
    '操作系统': ['操作系统', 'os'],
    '计算机网络': ['计网', '计算机网络'],
    '英语一': ['英语', '英一'],
    '英语二': ['英语', '英二'],
    '数学一': ['数学', '数一'],
    '数学二': ['数学', '数二'],
    '数学三': ['数学', '数三'],
  };
  static final durationPattern = RegExp(
    r'(半|\d+(?:\.\d+)?|[零〇一二两三四五六七八九十百千]+)\s*(?:个\s*)?(半\s*)?(小时|钟头|分钟|分|刻钟|hours?|hrs?|h|minutes?|mins?|min|m)(半)?',
    caseSensitive: false,
  );
  static double number(String value) {
    if (value == '半') return .5;
    final arabic = double.tryParse(value);
    if (arabic != null) return arabic;
    const digits = {
      '零': 0,
      '〇': 0,
      '一': 1,
      '二': 2,
      '两': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };
    const units = {'十': 10, '百': 100, '千': 1000};
    var sum = 0, digit = 0;
    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);
      if (units.containsKey(char)) {
        sum += (digit == 0 ? 1 : digit) * units[char]!;
        digit = 0;
      } else {
        digit = digits[char] ?? 0;
      }
    }
    return (sum + digit).toDouble();
  }

  static TaskInputResult parse(String input, List<Subject> subjects) {
    final normalized = input
        .replaceAll(durationPattern, '')
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');
    final available = subjects
        .where(
          (s) =>
              s.archived == 0 &&
              (s.parentSubjectId == null ||
                  subjects.any(
                    (p) => p.id == s.parentSubjectId && p.archived == 0,
                  )),
        )
        .toList();
    final exact = available
        .where(
          (s) => normalized.contains(
            s.name.toLowerCase().replaceAll(RegExp(r'\s+'), ''),
          ),
        )
        .toList();
    final matched = [...exact];
    for (final subject in available) {
      if (exact.any((s) => s.id == subject.id)) continue;
      final terms = aliases[subject.name] ?? const <String>[];
      if (terms.any(
        (term) =>
            normalized.contains(term) &&
            !exact.any((s) => s.name.toLowerCase().contains(term)),
      )) {
        matched.add(subject);
      }
    }
    final roots = matched.map((s) => s.parentSubjectId ?? s.id).toSet();
    final subjectId = roots.length == 1 ? roots.single : null;
    final durations = durationPattern.allMatches(input).toList();
    double total = 0;
    var valid = durations.isNotEmpty;
    for (final match in durations) {
      final unit = match.group(3)!.toLowerCase();
      final amount =
          number(match.group(1)!) +
          (match.group(2) != null || match.group(4) != null ? .5 : 0);
      total +=
          amount *
          (['小时', '钟头', 'hour', 'hours', 'hr', 'hrs', 'h'].contains(unit)
              ? 60
              : unit == '刻钟'
              ? 15
              : 1);
      if (match.start > 0 && input[match.start - 1] == '-') valid = false;
    }
    // Ranges and alternatives are not silently interpreted as a sum.
    if (RegExp(r'到|至|或|~|～|—|\d\s*-\s*\d').hasMatch(input)) valid = false;
    final minutes = valid && total > 0 && total <= 525600
        ? total.round()
        : null;
    var title = minutes == null
        ? input.trim()
        : input.replaceAll(durationPattern, '').trim();
    title = title.replaceAll(RegExp(r'[，,。；;\s]+$'), '');
    if (title.isEmpty) title = input.trim();
    final parts = <String>[];
    if (subjectId != null) {
      final root = available.firstWhere((s) => s.id == subjectId);
      parts.add('识别到科目：${root.name}');
    } else {
      parts.add(roots.length > 1 ? '无法确定科目，请手动选择' : '无法识别科目，请手动选择或添加细分科目');
    }
    parts.add(minutes != null ? '识别到时长：$minutes 分钟' : '无法识别时长，可手动填写预计分钟');
    return TaskInputResult(
      title,
      subjectId,
      minutes,
      subjectId == null && minutes == null
          ? '无法识别任务，请手动选择科目并填写预计分钟。'
          : parts.join('；'),
    );
  }
}
