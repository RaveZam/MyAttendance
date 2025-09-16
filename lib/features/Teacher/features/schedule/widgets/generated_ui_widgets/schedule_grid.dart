import 'package:flutter/material.dart';

class ScheduleGrid extends StatelessWidget {
  final Map<String, Map<String, String>> weeklySchedule;

  const ScheduleGrid({super.key, required this.weeklySchedule});

  @override
  Widget build(BuildContext context) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final timeSlots = _generateTimeSlots(weeklySchedule);

    final dayColors = [
      Colors.pink[50]!, // Monday
      Colors.yellow[50]!, // Tuesday
      Colors.green[50]!, // Wednesday
      Colors.blue[50]!, // Thursday
      Colors.purple[50]!, // Friday
    ];

    final dayHeaderColors = [
      Colors.pink[100]!, // Monday
      Colors.yellow[100]!, // Tuesday
      Colors.green[100]!, // Wednesday
      Colors.blue[100]!, // Thursday
      Colors.purple[100]!, // Friday
    ];

    return Column(
      children: [
        // Day headers
        Container(
          height: 35,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'TIME',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              ...days.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final isLast = index == days.length - 1;
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: dayHeaderColors[index],
                      border: Border(
                        left: BorderSide(color: Colors.grey[300]!),
                      ),
                      borderRadius: isLast
                          ? const BorderRadius.only(
                              topRight: Radius.circular(12),
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        day.substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Time rows
        Column(
          children: timeSlots.asMap().entries.map((entry) {
            final timeIndex = entry.key;
            final time = entry.value;
            final isLast = timeIndex == timeSlots.length - 1;

            return Container(
              height: 40,
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: Colors.grey[200]!)),
                borderRadius: isLast
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Time label
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        right: BorderSide(color: Colors.grey[300]!),
                      ),
                      borderRadius: isLast
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),

                  // Cells
                  ...days.asMap().entries.map((dayEntry) {
                    final dayIndex = dayEntry.key;
                    final day = dayEntry.value.toLowerCase();
                    final activity = _resolveActivityForTime(
                      weeklySchedule[day] ?? const {},
                      time,
                    );
                    final isLastDay = dayIndex == days.length - 1;

                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: dayColors[dayIndex],
                          border: Border(
                            left: BorderSide(color: Colors.grey[300]!),
                          ),
                          borderRadius: isLast && isLastDay
                              ? const BorderRadius.only(
                                  bottomRight: Radius.circular(12),
                                )
                              : null,
                        ),
                        child: Center(
                          child: activity.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        blurRadius: 1,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    activity,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Resolve an activity for a given hour label, accepting keys like
  /// "7:00 AM" or ranges like "7:00 AM - 8:30 AM".
  String _resolveActivityForTime(
    Map<String, String> daySchedule,
    String timeLabel,
  ) {
    // Direct match first
    final direct = daySchedule[timeLabel];
    if (direct != null && direct.isNotEmpty) return direct;

    // Try to find a range whose start matches this label
    for (final entry in daySchedule.entries) {
      final startLabel = _normalizeStartLabel(entry.key);
      if (startLabel == timeLabel) return entry.value;
    }
    return '';
  }

  /// Generate hourly slots based on available times in the schedule.
  /// Supports keys like "7:00 AM" and ranges like "7:00 AM - 8:30 AM".
  List<String> _generateTimeSlots(
    Map<String, Map<String, String>> weeklySchedule,
  ) {
    int earliestHour = 8; // fallback start
    int latestHour = 17; // fallback end

    for (final daySchedule in weeklySchedule.values) {
      for (final key in daySchedule.keys) {
        final startEnd = _extractStartEndHours(key);
        if (startEnd == null) continue;
        final start = startEnd.item1;
        final end = startEnd.item2;
        if (start < earliestHour) earliestHour = start;
        if (end > latestHour) latestHour = end;
      }
    }

    final labels = <String>[];
    for (int hour = earliestHour; hour <= latestHour; hour++) {
      labels.add(_formatHourLabel(hour));
    }
    return labels;
  }

  /// Extract start and end hours (24h) from a label like
  /// "7:00 AM - 8:30 AM" or a single time like "7:00 AM".
  /// Returns a tuple (startHour, endHour) with end rounded up to next hour if needed.
  _Tuple2? _extractStartEndHours(String label) {
    final parts = label.split('-');
    if (parts.length == 2) {
      final start = _parseHour12(parts[0].trim());
      final endRaw = _parseHour12(parts[1].trim());
      return _Tuple2(
        start.item1,
        endRaw.item1 == start.item1
            ? (start.item1 + 1) // ensure at least one hour span
            : endRaw.item1,
      );
    }
    // Single time label
    final single = _parseHour12(label.trim());
    return _Tuple2(single.item1, single.item1);
  }

  /// Parse "7:00 AM" to (hour24, minutes)
  _Tuple2 _parseHour12(String text) {
    final m = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (m == null) {
      // Fallback for "7 AM" style (without minutes)
      final m2 = RegExp(
        r'^(\d{1,2})\s*(AM|PM)$',
        caseSensitive: false,
      ).firstMatch(text);
      if (m2 == null) return _Tuple2(8, 0); // default
      final h = int.parse(m2.group(1)!);
      final period = m2.group(2)!.toUpperCase();
      final hour24 = _to24Hour(h, 0, period);
      return _Tuple2(hour24, 0);
    }
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    final period = m.group(3)!.toUpperCase();
    final hour24 = _to24Hour(h, min, period);
    return _Tuple2(hour24, min);
  }

  int _to24Hour(int hour, int minute, String period) {
    int h = hour % 12;
    if (period == 'PM') h += 12;
    return h;
  }

  String _formatHourLabel(int hour24) {
    int displayHour = hour24 % 12;
    if (displayHour == 0) displayHour = 12;
    final suffix = hour24 < 12 ? 'AM' : 'PM';
    return '$displayHour:00 $suffix';
  }

  /// From a key that may be a range, produce a normalized start label
  /// like "7:00 AM" matching our row labels.
  String _normalizeStartLabel(String key) {
    final parts = key.split('-');
    final startText = parts.first.trim();
    final parsed = _parseHour12(startText);
    return _formatHourLabel(parsed.item1);
  }
}

class _Tuple2 {
  final int item1;
  final int item2;
  _Tuple2(this.item1, this.item2);
}
