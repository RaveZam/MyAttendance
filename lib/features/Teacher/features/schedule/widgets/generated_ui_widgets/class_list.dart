import 'package:flutter/material.dart';
import 'class_card.dart';
import 'empty_classes_state.dart';

class ClassList extends StatelessWidget {
  final List<Map<String, dynamic>> scheduleData;

  const ClassList({super.key, required this.scheduleData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Classes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ..._buildClassList(),
      ],
    );
  }

  List<Widget> _buildClassList() {
    // Group schedule data by subject to create class entries
    final Map<String, List<Map<String, dynamic>>> classesBySubject = {};

    for (final schedule in scheduleData) {
      final subject = schedule['subject']?.toString() ?? '';
      if (subject.isNotEmpty) {
        if (!classesBySubject.containsKey(subject)) {
          classesBySubject[subject] = [];
        }
        classesBySubject[subject]!.add(schedule);
      }
    }

    // If no schedule data, show empty state
    if (classesBySubject.isEmpty) {
      return [const EmptyClassesState()];
    }

    // Generate class list from actual data
    return classesBySubject.entries.map((entry) {
      final subject = entry.key;
      final classSessions = entry.value;

      // Get unique days for this subject
      final uniqueDays = classSessions
          .map((s) => s['day']?.toString().toLowerCase() ?? '')
          .toSet();

      // Calculate next session time
      final now = DateTime.now();
      final today = now.weekday; // 1 = Monday, 7 = Sunday
      String nextSession = 'No upcoming sessions';

      // Find next session
      for (final session in classSessions) {
        final day = session['day']?.toString().toLowerCase() ?? '';
        final time = session['time']?.toString() ?? '';

        if (day.isNotEmpty && time.isNotEmpty) {
          final dayNumber = _getDayNumber(day);
          if (dayNumber != null && dayNumber >= today) {
            final formattedTime = _formatTime(time);
            if (formattedTime.isNotEmpty) {
              nextSession = dayNumber == today
                  ? 'Today $formattedTime'
                  : '${_getDayName(dayNumber)} $formattedTime';
              break;
            }
          }
        }
      }

      // Get subject icon and color
      final subjectInfo = _getSubjectInfo(subject);

      return ClassCard(
        subject: subject,
        sessionCount: classSessions.length,
        daysPerWeek: uniqueDays.length,
        nextSession: nextSession,
        icon: subjectInfo['icon'] as IconData,
        color: subjectInfo['color'] as Color,
      );
    }).toList();
  }

  // Helper function to get day number from day name
  int? _getDayNumber(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
      case 'mon':
        return 1;
      case 'tuesday':
      case 'tue':
        return 2;
      case 'wednesday':
      case 'wed':
        return 3;
      case 'thursday':
      case 'thu':
        return 4;
      case 'friday':
      case 'fri':
        return 5;
      case 'saturday':
      case 'sat':
        return 6;
      case 'sunday':
      case 'sun':
        return 7;
      default:
        return null;
    }
  }

  // Helper function to get day name from day number
  String _getDayName(int dayNumber) {
    switch (dayNumber) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  // Helper function to get subject icon and color
  Map<String, dynamic> _getSubjectInfo(String subject) {
    final subjectLower = subject.toLowerCase();

    if (subjectLower.contains('math') ||
        subjectLower.contains('calculus') ||
        subjectLower.contains('algebra')) {
      return {'icon': Icons.calculate, 'color': Colors.blue};
    } else if (subjectLower.contains('physics')) {
      return {'icon': Icons.science, 'color': Colors.green};
    } else if (subjectLower.contains('chemistry')) {
      return {'icon': Icons.science, 'color': Colors.orange};
    } else if (subjectLower.contains('computer') ||
        subjectLower.contains('programming') ||
        subjectLower.contains('software')) {
      return {'icon': Icons.computer, 'color': Colors.purple};
    } else if (subjectLower.contains('biology') ||
        subjectLower.contains('bio')) {
      return {'icon': Icons.biotech, 'color': Colors.teal};
    } else if (subjectLower.contains('english') ||
        subjectLower.contains('literature')) {
      return {'icon': Icons.book, 'color': Colors.red};
    } else if (subjectLower.contains('history')) {
      return {'icon': Icons.history_edu, 'color': Colors.brown};
    } else if (subjectLower.contains('art') ||
        subjectLower.contains('design')) {
      return {'icon': Icons.palette, 'color': Colors.pink};
    } else {
      return {'icon': Icons.school, 'color': Colors.grey};
    }
  }

  // Helper method to format time strings from your data
  String _formatTime(String time) {
    if (time.isEmpty) return '';

    // Handle time ranges like "09:00-10:30" - take the start time
    if (time.contains('-')) {
      time = time.split('-')[0].trim();
    }

    // Try to parse different time formats
    final timePatterns = [
      RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false),
      RegExp(r'(\d{1,2}):(\d{2})'),
      RegExp(r'(\d{1,2})\s*(AM|PM)', caseSensitive: false),
    ];

    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(time);
      if (match != null) {
        final hour = int.tryParse(match.group(1)!) ?? 0;
        final minute = match.group(2)?.isNotEmpty == true
            ? match.group(2)!
            : '00';
        // Only access group(3) if it exists (for patterns with AM/PM)
        final period = match.groupCount >= 3
            ? (match.group(3)?.toUpperCase() ?? '')
            : '';

        // Convert to 12-hour format if needed
        String formattedHour = hour.toString();
        String amPm = period;

        if (period.isEmpty) {
          // Assume 24-hour format
          if (hour >= 12) {
            amPm = 'PM';
            if (hour > 12) formattedHour = (hour - 12).toString();
          } else {
            amPm = 'AM';
            if (hour == 0) formattedHour = '12';
          }
        }

        return '$formattedHour:${minute.padLeft(2, '0')} $amPm';
      }
    }

    return time; // Return original if no pattern matches
  }
}
