class FormatTime {
  // Helper method to format time strings from your data
  String formatTime(String time) {
    if (time.isEmpty) return '';

    // Handle time ranges like "1:00-2:00" or "09:00-10:30" - take the start time
    if (time.contains('-')) {
      time = time.split('-')[0].trim();
    }

    // Try to parse different time formats
    final timePatterns = [
      // 12-hour format with AM/PM: "1:00 PM", "12:30 AM"
      RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false),
      // 12-hour format without AM/PM: "1:00", "12:30" (assume AM if < 12, PM if >= 12)
      RegExp(r'(\d{1,2}):(\d{2})'),
      // 24-hour format: "13:00", "09:30"
      RegExp(r'(\d{1,2}):(\d{2})'),
      // Hour only with AM/PM: "1 PM", "12 AM"
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

        // Convert to 12-hour format
        String formattedHour = hour.toString();
        String amPm = period;

        if (period.isEmpty) {
          // No AM/PM specified - determine based on hour
          if (hour == 0) {
            formattedHour = '12';
            amPm = 'AM';
          } else if (hour < 12) {
            formattedHour = hour.toString();
            amPm = 'AM';
          } else if (hour == 12) {
            formattedHour = '12';
            amPm = 'PM';
          } else {
            formattedHour = (hour - 12).toString();
            amPm = 'PM';
          }
        } else {
          // AM/PM specified - handle 12-hour conversion
          if (period == 'AM' && hour == 12) {
            formattedHour = '12';
          } else if (period == 'PM' && hour != 12) {
            formattedHour = (hour + 12).toString();
          } else {
            formattedHour = hour.toString();
          }
        }

        return '$formattedHour:${minute.padLeft(2, '0')} $amPm';
      }
    }

    return time; // Return original if no pattern matches
  }

  // Helper method to convert time to 24-hour format for sorting/comparison
  int getHourIn24Format(String time) {
    if (time.isEmpty) return 0;

    // Handle time ranges - take the start time
    if (time.contains('-')) {
      time = time.split('-')[0].trim();
    }

    final timePatterns = [
      // 12-hour format with AM/PM
      RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)', caseSensitive: false),
      // 12-hour format without AM/PM
      RegExp(r'(\d{1,2}):(\d{2})'),
      // Hour only with AM/PM
      RegExp(r'(\d{1,2})\s*(AM|PM)', caseSensitive: false),
    ];

    for (final pattern in timePatterns) {
      final match = pattern.firstMatch(time);
      if (match != null) {
        int hour = int.tryParse(match.group(1)!) ?? 0;
        final period = match.groupCount >= 3
            ? (match.group(3)?.toUpperCase() ?? '')
            : '';

        if (period.isEmpty) {
          // No AM/PM - assume 24-hour format if hour > 12, otherwise AM
          if (hour <= 12) {
            // Could be AM or PM, but for sorting we'll treat as AM
            return hour == 0 ? 0 : hour;
          } else {
            // Already in 24-hour format
            return hour;
          }
        } else {
          // Convert 12-hour to 24-hour
          if (period == 'AM' && hour == 12) {
            return 0;
          } else if (period == 'PM' && hour != 12) {
            return hour + 12;
          } else {
            return hour;
          }
        }
      }
    }

    return 0;
  }
}
