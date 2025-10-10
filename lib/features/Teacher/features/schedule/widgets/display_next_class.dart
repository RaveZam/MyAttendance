import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/core/database/app_database.dart';

class DisplayNextClass extends StatefulWidget {
  const DisplayNextClass({super.key});

  @override
  State<DisplayNextClass> createState() => _DisplayNextClassState();
}

class _DisplayNextClassState extends State<DisplayNextClass> {
  Schedule? _nextSchedule;
  Subject? _nextSubject;
  DateTime? _nextStart;
  DateTime? _nextEnd;

  @override
  void initState() {
    super.initState();
    _loadNextClass();
  }

  Future<void> _loadNextClass() async {
    try {
      final db = AppDatabase.instance;
      final schedules = await db.getAllSchedules();
      if (schedules.isEmpty) {
        setState(() {
          _nextSchedule = null;
          _nextSubject = null;
          _nextStart = null;
          _nextEnd = null;
        });
        return;
      }

      final now = DateTime.now();
      final todayWeekday = now.weekday;
      DateTime? bestStart; // earliest upcoming start today
      DateTime? bestEnd;
      Schedule? bestSchedule;

      for (final s in schedules) {
        final schedWeekday = _weekdayFromName(s.day);
        if (schedWeekday == null || schedWeekday != todayWeekday) continue;

        final startToday = _combineTodayTime(now, s.startTime);
        final endToday = _combineTodayTime(now, s.endTime);
        if (startToday == null || endToday == null) continue;

        // Only consider classes that start later today
        if (startToday.isAfter(now)) {
          if (bestStart == null || startToday.isBefore(bestStart)) {
            bestStart = startToday;
            bestEnd = endToday;
            bestSchedule = s;
          }
        }
      }

      if (bestSchedule == null) {
        setState(() {
          _nextSchedule = null;
          _nextSubject = null;
          _nextStart = null;
          _nextEnd = null;
        });
        return;
      }

      Subject? subj;
      try {
        final list = await db.getSubjectByID(bestSchedule.subjectId);
        if (list.isNotEmpty) subj = list.first;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _nextSchedule = bestSchedule;
        _nextSubject = subj;
        _nextStart = bestStart;
        _nextEnd = bestEnd;
      });
    } catch (e) {
      debugPrint('Failed to load next class: $e');
      if (!mounted) return;
      setState(() {
        _nextSchedule = null;
        _nextSubject = null;
        _nextStart = null;
        _nextEnd = null;
      });
    } finally {
      // no-op
    }
  }

  DateTime? _combineTodayTime(DateTime anchor, String timeStr) {
    final t = _tryParseTime(timeStr);
    if (t == null) return null;
    return DateTime(anchor.year, anchor.month, anchor.day, t.hour, t.minute);
  }

  // Removed unused _computeNextOccurrence; we only compute today's times

  DateTime? _tryParseTime(String input) {
    final formats = <DateFormat>[
      DateFormat('h:mm a'),
      DateFormat('hh:mm a'),
      DateFormat('H:mm'),
      DateFormat('HH:mm'),
    ];
    for (final fmt in formats) {
      try {
        final d = fmt.parse(input);
        return DateTime(0, 1, 1, d.hour, d.minute);
      } catch (_) {}
    }
    return null;
  }

  int? _weekdayFromName(String name) {
    final normalized = name.trim().toLowerCase();
    switch (normalized) {
      case 'monday':
      case 'mon':
        return DateTime.monday;
      case 'tuesday':
      case 'tue':
      case 'tues':
        return DateTime.tuesday;
      case 'wednesday':
      case 'wed':
        return DateTime.wednesday;
      case 'thursday':
      case 'thu':
      case 'thurs':
        return DateTime.thursday;
      case 'friday':
      case 'fri':
        return DateTime.friday;
      case 'saturday':
      case 'sat':
        return DateTime.saturday;
      case 'sunday':
      case 'sun':
        return DateTime.sunday;
    }
    return null;
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';
    final f = DateFormat('h:mm a');
    return '${f.format(start)} - ${f.format(end)}';
  }

  String _startsInText(DateTime? start) {
    if (start == null) return '';
    final now = DateTime.now();
    final diff = start.difference(now);
    if (diff.inMinutes <= 0) return 'Starting now';
    if (diff.inMinutes < 60) return 'Starts in ${diff.inMinutes} min';
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (minutes == 0) return 'Starts in $hours hr';
    return 'Starts in ${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final subjectTitle = _nextSubject?.subjectName ?? 'No upcoming class';
    final subtitle = _nextSubject?.subjectCode ?? '';
    final timeRange = _formatRange(_nextStart, _nextEnd);
    final room = _nextSchedule?.room ?? 'TBD';
    final startsIn = _startsInText(_nextStart);

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _nextSchedule == null
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _nextSchedule == null ? 'NO UPCOMING' : 'UPCOMING',
                    style: TextStyle(
                      color: _nextSchedule == null
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFFF59E0B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    room,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subjectTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: Color(0xFF374151),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeRange.isEmpty ? '—' : timeRange,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    startsIn.isEmpty ? '' : startsIn,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: 16,
          bottom: 16,
          child: Container(
            width: 6,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
