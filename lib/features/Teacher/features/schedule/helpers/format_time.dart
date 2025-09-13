class FormatTime {
  // Helper method to format time strings from your data
  String formatTime(String time) {
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
