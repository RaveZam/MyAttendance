import 'package:flutter/material.dart';

class ScheduleGrid extends StatelessWidget {
  final Map<String, Map<String, String>> weeklySchedule;

  const ScheduleGrid({super.key, required this.weeklySchedule});

  @override
  Widget build(BuildContext context) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final timeSlots = _generateTimeSlots(weeklySchedule);

    final dayColors = [
      Colors.pink[50]!, // Monday - Light pink
      Colors.yellow[50]!, // Tuesday - Light yellow
      Colors.green[50]!, // Wednesday - Light green
      Colors.blue[50]!, // Thursday - Light blue
      Colors.purple[50]!, // Friday - Light purple
    ];

    final dayHeaderColors = [
      Colors.pink[100]!, // Monday header
      Colors.yellow[100]!, // Tuesday header
      Colors.green[100]!, // Wednesday header
      Colors.blue[100]!, // Thursday header
      Colors.purple[100]!, // Friday header
    ];

    return Column(
      children: [
        // Days header
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
              // Time column header
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
              // Day headers
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

        // Time slots and schedule
        Column(
          children: timeSlots.asMap().entries.map((entry) {
            final timeIndex = entry.key;
            final time = entry.value;
            final isLast = timeIndex == timeSlots.length - 1;
            return Container(
              height: 35,
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
                  // Time slot
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

                  // Day columns
                  ...days.asMap().entries.map((dayEntry) {
                    final dayIndex = dayEntry.key;
                    final day = dayEntry.value;
                    final dayKey = day.toLowerCase();
                    final activity = weeklySchedule[dayKey]?[time] ?? '';
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
                                        color: Colors.black.withValues(
                                          alpha: 0.06,
                                        ),
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

  List<String> _generateTimeSlots(
    Map<String, Map<String, String>> weeklySchedule,
  ) {
    final timeSlots = <String>[];
    int latestHour = 7; // Start from 7 AM

    // Find the latest hour in the schedule
    for (final daySchedule in weeklySchedule.values) {
      for (final time in daySchedule.keys) {
        // Parse time to extract hour
        final timeMatch = RegExp(
          r'(\d{1,2}):(\d{2})\s*(AM|PM)',
          caseSensitive: false,
        ).firstMatch(time);
        if (timeMatch != null) {
          int hour = int.tryParse(timeMatch.group(1)!) ?? 0;
          final period = timeMatch.group(3)?.toUpperCase() ?? '';

          // Convert to 24-hour format
          if (period == 'PM' && hour != 12) {
            hour += 12;
          } else if (period == 'AM' && hour == 12) {
            hour = 0;
          }

          if (hour > latestHour) {
            latestHour = hour;
          }
        }
      }
    }

    // Generate time slots from 7 AM to latest hour + 1
    for (int hour = 7; hour <= latestHour + 1; hour++) {
      String displayHour = hour.toString();
      String period = 'AM';

      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) {
          displayHour = (hour - 12).toString();
        }
      }
      if (hour == 0) {
        displayHour = '12';
      }

      timeSlots.add('$displayHour:00 $period');
    }

    return timeSlots;
  }
}
