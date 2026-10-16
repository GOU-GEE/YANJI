import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'glass_controls.dart';

/// Two independent scrolling dates, with an explicit valid-range confirmation.
Future<DateTimeRange?> showGlassDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  required DateTimeRange initialDateRange,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<DateTimeRange>(
    context: context,
    builder: (context) => _GlassDateRangePicker(
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialDateRange,
    ),
  );
}

class _GlassDateRangePicker extends StatefulWidget {
  const _GlassDateRangePicker({
    required this.firstDate,
    required this.lastDate,
    required this.initialDateRange,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange initialDateRange;

  @override
  State<_GlassDateRangePicker> createState() => _GlassDateRangePickerState();
}

class _GlassDateRangePickerState extends State<_GlassDateRangePicker> {
  late DateTime start = widget.initialDateRange.start;
  late DateTime end = widget.initialDateRange.end;
  late final int _dayCount = _indexOf(widget.lastDate) + 1;
  late final FixedExtentScrollController _startController =
      FixedExtentScrollController(initialItem: _indexOf(start));
  late final FixedExtentScrollController _endController =
      FixedExtentScrollController(initialItem: _indexOf(end));

  int _indexOf(DateTime date) => DateTime.utc(date.year, date.month, date.day)
      .difference(
        DateTime.utc(
          widget.firstDate.year,
          widget.firstDate.month,
          widget.firstDate.day,
        ),
      )
      .inDays;

  DateTime _dateAt(int index) => DateTime(
    widget.firstDate.year,
    widget.firstDate.month,
    widget.firstDate.day + index,
  );

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Widget _wheel({
    required Key key,
    required FixedExtentScrollController controller,
    required ValueChanged<DateTime> onChanged,
  }) => CupertinoPicker.builder(
    key: key,
    scrollController: controller,
    itemExtent: 38,
    magnification: 1.08,
    useMagnifier: true,
    onSelectedItemChanged: (index) => onChanged(_dateAt(index)),
    childCount: _dayCount,
    itemBuilder: (context, index) {
      final date = _dateAt(index);
      return Center(
        child: Text(
          '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
          maxLines: 1,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 580),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('自定义日期', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text('开始日期', style: theme.textTheme.labelLarge),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('结束日期', style: theme.textTheme.labelLarge),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 190,
              child: Row(
                children: [
                  Expanded(
                    child: _wheel(
                      key: const Key('custom-start-date'),
                      controller: _startController,
                      onChanged: (value) => setState(() => start = value),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _wheel(
                      key: const Key('custom-end-date'),
                      controller: _endController,
                      onChanged: (value) => setState(() => end = value),
                    ),
                  ),
                ],
              ),
            ),
            if (start.isAfter(end))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '结束日期不能早于开始日期',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GlassTextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const SizedBox(width: 8),
                GlassFilledButton(
                  onPressed: start.isAfter(end)
                      ? null
                      : () =>
                            Navigator.of(context)
                                .pop(DateTimeRange(start: start, end: end)),
                  child: const Text('确定'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
