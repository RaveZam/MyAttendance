import 'package:flutter/material.dart';

class ClassDetailsInfoCard extends StatelessWidget {
  final String subject;
  final String courseCode;
  final String room;
  final String startTime;
  final String endTime;
  final String semester;
  final String yearLevel;
  final String section;
  final String profId;
  final Iterable sessions;

  const ClassDetailsInfoCard({
    super.key,
    required this.subject,
    required this.courseCode,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.semester,
    required this.yearLevel,
    required this.section,
    required this.profId,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header with centered icon, title and subject code
          Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school, color: scheme.onPrimary, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                subject,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                courseCode,
                style: TextStyle(
                  fontSize: 18,
                  color: scheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Class Details Grid
          _buildDetailsGrid(scheme),

          const SizedBox(height: 20),

          // Schedule Information
          _buildScheduleInfo(scheme),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid(ColorScheme scheme) {
    return Column(
      children: [
        _DetailRow(
          icon: Icons.calendar_today,
          label: 'Semester',
          value: semester,
          scheme: scheme,
        ),
        const SizedBox(height: 12),
        _DetailRow(
          icon: Icons.grade,
          label: 'Year Level',
          value: yearLevel,
          scheme: scheme,
        ),
        const SizedBox(height: 12),
        _DetailRow(
          icon: Icons.group,
          label: 'Section',
          value: section,
          scheme: scheme,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildScheduleInfo(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: scheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSessionsDisplay(scheme),
        ],
      ),
    );
  }

  Widget _buildSessionsDisplay(ColorScheme scheme) {
    // If sessions are available, display them
    if (sessions.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...sessions.map<Widget>((session) {
            // Handle different session data structures
            String startTime = '';
            String endTime = '';
            String room = '';
            String day = '';

            if (session is Map<String, dynamic>) {
              startTime = session['startTime']?.toString() ?? '';
              endTime = session['endTime']?.toString() ?? '';
              room = session['room']?.toString() ?? '';
              day = session['day']?.toString() ?? '';
            } else {
              // If session is not a Map, try to access properties directly
              try {
                startTime = session.startTime?.toString() ?? '';
                endTime = session.endTime?.toString() ?? '';
                room = session.room?.toString() ?? '';
                day = session.day?.toString() ?? '';
              } catch (e) {
                debugPrint('Error accessing session properties: $e');
                startTime = 'Unknown';
                endTime = 'Unknown';
                room = 'Unknown';
                day = 'Unknown';
              }
            }

            String formattedStartTime = _formatTo12Hour(startTime);
            String formattedEndTime = _formatTo12Hour(endTime);

            String displayText = '';
            if (day.isNotEmpty && day != 'Unknown') {
              displayText = '$day $formattedStartTime - $formattedEndTime';
            } else {
              displayText = '$formattedStartTime - $formattedEndTime';
            }

            if (room.isNotEmpty && room != 'Unknown') {
              displayText += ' | $room';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    } else {
      // Fallback to basic schedule display
      String formattedStartTime = _formatTo12Hour(startTime);
      String formattedEndTime = _formatTo12Hour(endTime);

      return Text(
        '$formattedStartTime - $formattedEndTime',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: scheme.primary,
        ),
      );
    }
  }

  String _formatTo12Hour(String timeString) {
    if (timeString.isEmpty || timeString == 'Unknown') {
      return timeString;
    }

    try {
      // Handle different time formats
      if (timeString.contains(':')) {
        // Parse time string (e.g., "09:00", "14:30", "9:00 AM")
        List<String> parts = timeString.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          String minutes = parts[1].split(
            ' ',
          )[0]; // Remove AM/PM if already present

          // If already in 12-hour format, return as is
          if (timeString.toUpperCase().contains('AM') ||
              timeString.toUpperCase().contains('PM')) {
            return timeString;
          }

          // Convert 24-hour to 12-hour format
          String period = hour >= 12 ? 'PM' : 'AM';
          int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

          return '$displayHour:$minutes $period';
        }
      }

      // If parsing fails, return original string
      return timeString;
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return timeString;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme scheme;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: scheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: scheme.onSurfaceVariant, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
