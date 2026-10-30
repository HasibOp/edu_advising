import 'package:flutter/material.dart';

import '../models/class_slot.dart';
import '../services/catalog.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class WeekRoutineGrid extends StatelessWidget {
  const WeekRoutineGrid({super.key, required this.slots});

  final List<ClassSlot> slots;

  static const double _dayWidth = 108;
  static const double _axisWidth = 46;
  static const double _perMinute = 1.05;
  static const double _headerHeight = 34;

  @override
  Widget build(BuildContext context) {
    final days = Catalog.instance.days;
    var start = 8 * 60 + 30;
    var end = 18 * 60;
    for (final s in slots) {
      if (s.startMinute < start) start = s.startMinute ~/ 30 * 30;
      if (s.endMinute > end) end = (s.endMinute + 29) ~/ 30 * 30;
    }
    final height = (end - start) * _perMinute;
    final lanes = layoutRoutineLanes(slots);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: _axisWidth + days.length * _dayWidth,
        height: _headerHeight + height + 8,
        child: Stack(
          children: [
            for (var i = 0; i < days.length; i++)
              Positioned(
                left: _axisWidth + i * _dayWidth,
                top: 0,
                width: _dayWidth,
                height: _headerHeight - 4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(days[i].substring(0, 3).toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            for (var m = (start + 29) ~/ 30 * 30; m <= end; m += 30)
              Positioned(
                left: 0,
                right: 0,
                top: _headerHeight + (m - start) * _perMinute,
                child: Row(
                  children: [
                    SizedBox(
                      width: _axisWidth,
                      child: Text(m % 60 == 0 ? Formatters.clock(m) : '',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: m % 60 == 0 ? AppColors.border : AppColors.border.withAlpha(90),
                      ),
                    ),
                  ],
                ),
              ),
            for (final s in slots)
              if (days.contains(s.day))
                Positioned(
                  left: _axisWidth +
                      days.indexOf(s.day) * _dayWidth +
                      2 +
                      lanes[s]!.$1 * (_dayWidth - 4) / lanes[s]!.$2,
                  top: _headerHeight + (s.startMinute - start) * _perMinute,
                  width: (_dayWidth - 4) / lanes[s]!.$2 - (lanes[s]!.$2 > 1 ? 1 : 0),
                  height: (s.endMinute - s.startMinute) * _perMinute - 2,
                  child: _Block(slot: s, compact: lanes[s]!.$2 > 1),
                ),
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
Map<ClassSlot, (int, int)> layoutRoutineLanes(List<ClassSlot> slots) {
  final result = <ClassSlot, (int, int)>{};
  final byDay = <String, List<ClassSlot>>{};
  for (final s in slots) {
    byDay.putIfAbsent(s.day, () => []).add(s);
  }
  for (final list in byDay.values) {
    list.sort((a, b) => a.startMinute.compareTo(b.startMinute));
    var group = <ClassSlot>[];
    var groupEnd = -1;
    void flush() {
      if (group.isEmpty) return;
      final laneEnds = <int>[];
      final laneOf = <ClassSlot, int>{};
      for (final s in group) {
        var lane = laneEnds.indexWhere((end) => end <= s.startMinute);
        if (lane < 0) {
          lane = laneEnds.length;
          laneEnds.add(s.endMinute);
        } else {
          laneEnds[lane] = s.endMinute;
        }
        laneOf[s] = lane;
      }
      for (final s in group) {
        result[s] = (laneOf[s]!, laneEnds.length);
      }
      group = <ClassSlot>[];
    }

    for (final s in list) {
      if (group.isNotEmpty && s.startMinute >= groupEnd) flush();
      group.add(s);
      groupEnd = group.length == 1 ? s.endMinute : (s.endMinute > groupEnd ? s.endMinute : groupEnd);
    }
    flush();
  }
  return result;
}

class _Block extends StatelessWidget {
  const _Block({required this.slot, this.compact = false});

  final ClassSlot slot;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${slot.label} ${Catalog.instance.titleOf(slot.courseCode)}\n'
          '${slot.day} ${Formatters.routineTime(slot.time)}, Room ${slot.room}\n'
          '${Catalog.instance.facultyName(slot.faculty)}',
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.blockColorFor(slot.courseCode),
          borderRadius: BorderRadius.circular(8),
          border: slot.isLab ? Border.all(color: AppColors.primary, width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(slot.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 9.5 : 11.5,
                    color: AppColors.text)),
            Text(
              compact ? slot.room : '${slot.isLab ? 'Lab' : 'Theory'} - ${slot.room}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: compact ? 9 : 10, color: AppColors.text),
            ),
            if (!compact)
              Text(slot.faculty,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class DayRoutineList extends StatelessWidget {
  const DayRoutineList({super.key, required this.slots});

  final List<ClassSlot> slots;

  @override
  Widget build(BuildContext context) {
    final catalog = Catalog.instance;
    return Column(
      children: [
        for (final day in catalog.days)
          Builder(builder: (context) {
            final today = slots.where((s) => s.day == day).toList()
              ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Text(day,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ),
                  if (today.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('No classes', style: TextStyle(color: AppColors.textMuted)),
                    ),
                  for (final s in today)
                    ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 78,
                        child: Text(Formatters.routineTime(s.time),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      ),
                      title: Text('${s.label}  ${catalog.titleOf(s.courseCode)}',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${s.isLab ? 'Lab' : 'Theory'} - Room ${s.room} - ${s.faculty}'),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

List<List<String>> routinePdfRows(List<ClassSlot> slots) {
  final days = Catalog.instance.days;
  final sorted = slots.toList()
    ..sort((a, b) {
      final d = days.indexOf(a.day).compareTo(days.indexOf(b.day));
      return d != 0 ? d : a.startMinute.compareTo(b.startMinute);
    });
  return [
    for (final s in sorted)
      [
        s.day,
        s.time.replaceAll('.', ':'),
        s.label,
        Catalog.instance.titleOf(s.courseCode),
        s.isLab ? 'Lab' : 'Theory',
        s.room,
        s.faculty,
      ],
  ];
}
