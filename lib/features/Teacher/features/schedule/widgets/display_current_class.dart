import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/features/Teacher/features/attendance/pages/attendance_page.dart';
import 'package:myattendance/features/Teacher/features/class_details/pages/class_details_page.dart';
import 'package:drift/drift.dart' as drift;

class DisplayCurrentClass extends StatefulWidget {
  const DisplayCurrentClass({super.key});

  @override
  State<DisplayCurrentClass> createState() => _DisplayCurrentClassState();
}

class _DisplayCurrentClassState extends State<DisplayCurrentClass>
    with WidgetsBindingObserver {
  Schedule? _liveSchedule;
  Subject? _liveSubject;
  DateTime? _start;
  DateTime? _end;
  bool _hasOngoing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentClass();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadCurrentClass();
    }
  }

  Future<void> _loadCurrentClass() async {
    try {
      final db = AppDatabase.instance;
      final schedules = await db.getAllSchedules();
      if (schedules.isEmpty) {
        setState(() {
          _liveSchedule = null;
          _liveSubject = null;
          _start = null;
          _end = null;
        });
        return;
      }

      final now = DateTime.now();
      final todayWeekday = now.weekday;
      Schedule? current;
      DateTime? currentStart;
      DateTime? currentEnd;

      for (final s in schedules) {
        final schedWeekday = _weekdayFromName(s.day);
        if (schedWeekday == null || schedWeekday != todayWeekday) continue;

        final startToday = _combineTodayTime(now, s.startTime);
        final endToday = _combineTodayTime(now, s.endTime);
        if (startToday == null || endToday == null) continue;

        // Live if now is within [start, end]
        final isLive =
            (now.isAfter(startToday) || now.isAtSameMomentAs(startToday)) &&
            now.isBefore(endToday);
        if (isLive) {
          if (currentStart == null || startToday.isBefore(currentStart)) {
            current = s;
            currentStart = startToday;
            currentEnd = endToday;
          }
        }
      }

      if (current == null) {
        setState(() {
          _liveSchedule = null;
          _liveSubject = null;
          _start = null;
          _end = null;
        });
        return;
      }

      Subject? subj;
      try {
        final list = await db.getSubjectByID(current.subjectId);
        if (list.isNotEmpty) subj = list.first;
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _liveSchedule = current;
        _liveSubject = subj;
        _start = currentStart;
        _end = currentEnd;
      });

      // Check ongoing session for dynamic button label
      if (subj != null) {
        final ongoing = await db.checkForOngoingSession(subj.id);
        if (!mounted) return;
        setState(() {
          _hasOngoing = ongoing.isNotEmpty;
        });
      } else {
        setState(() {
          _hasOngoing = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load current class: $e');
      if (!mounted) return;
      setState(() {
        _liveSchedule = null;
        _liveSubject = null;
        _start = null;
        _end = null;
      });
    }
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

  DateTime? _combineTodayTime(DateTime anchor, String timeStr) {
    final t = _tryParseTime(timeStr);
    if (t == null) return null;
    return DateTime(anchor.year, anchor.month, anchor.day, t.hour, t.minute);
  }

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

  Future<void> _startOrResumeSession(BuildContext context, Subject subj) async {
    final db = AppDatabase.instance;
    final subjectId = subj.id;
    final ongoing = await db.checkForOngoingSession(subjectId);
    final activeSessionID = ongoing.isNotEmpty ? ongoing.first.id : 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: activeSessionID == 0
            ? const Text('Start Session?')
            : const Text('Resume Session?'),
        content: const Text('Are you sure you want to Start Session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    String sessionID;
    if (activeSessionID == 0) {
      final newSessionID = await db.insertSession(
        SessionsCompanion(
          subjectId: drift.Value(subjectId),
          startTime: drift.Value(DateTime.now()),
          endTime: drift.Value(DateTime.now()),
          status: drift.Value('ongoing'),
          synced: drift.Value(false),
          createdAt: drift.Value(DateTime.now()),
        ),
      );
      sessionID = newSessionID.toString();
    } else {
      sessionID = activeSessionID.toString();
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendancePage(
          subjectId: subjectId.toString(),
          sessionID: sessionID,
        ),
      ),
    ).then((_) async {
      // Always refresh state when returning from Attendance
      await _loadCurrentClass();
    });
  }

  void _viewSubjectDetails(BuildContext context, Subject subj) async {
    final db = AppDatabase.instance;
    final schedules = await db.getSchedulesBySubjectId(subj.id);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassDetailsPage(
          subject: subj.subjectName,
          courseCode: subj.subjectCode,
          room: schedules.isNotEmpty ? (schedules.first.room ?? '') : '',
          startTime: schedules.isNotEmpty ? schedules.first.startTime : '',
          endTime: schedules.isNotEmpty ? schedules.first.endTime : '',
          status: 'N/A',
          semester: '',
          classID: subj.id.toString(),
          yearLevel: subj.yearLevel,
          section: subj.section,
          profId: subj.profId,
          sessions: schedules
              .map(
                (e) => {
                  'day': e.day,
                  'startTime': e.startTime,
                  'endTime': e.endTime,
                  'room': e.room ?? '',
                },
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_liveSchedule == null || _liveSubject == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[500]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'No class live at the moment',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _CurrentClassCard(
      subject: _liveSubject!,
      schedule: _liveSchedule!,
      start: _start,
      end: _end,
      hasOngoing: _hasOngoing,
      onStartSession: () => _startOrResumeSession(context, _liveSubject!),
      onViewDetails: () => _viewSubjectDetails(context, _liveSubject!),
    );
  }
}

class _LoadingCard extends StatefulWidget {
  const _LoadingCard();

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(width: 10, height: 10, radius: 5),
                  const SizedBox(width: 8),
                  _shimmerBox(width: 70, height: 12, radius: 4),
                  const Spacer(),
                  _shimmerBox(width: 110, height: 12, radius: 4),
                ],
              ),
              const SizedBox(height: 16),
              _shimmerBox(width: 200, height: 16, radius: 6),
              const SizedBox(height: 8),
              _shimmerBox(width: 140, height: 14, radius: 6),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Spacer(),
                  _shimmerBox(width: 140, height: 36, radius: 10),
                ],
              ),
            ],
          ),
        ),
        // Thick left border
        Positioned(
          left: 16,
          top: 16,
          bottom: 16,
          child: Container(
            width: 6,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade200],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  // Removed circle shimmer helper as avatars are not shown in the new design
}

class _CurrentClassCard extends StatelessWidget {
  final Subject subject;
  final Schedule schedule;
  final DateTime? start;
  final DateTime? end;
  final bool hasOngoing;
  final VoidCallback onStartSession;
  final VoidCallback onViewDetails;

  const _CurrentClassCard({
    required this.subject,
    required this.schedule,
    required this.start,
    required this.end,
    required this.hasOngoing,
    required this.onStartSession,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.95),
            scheme.secondary.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                  color: scheme.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE NOW',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
              const Spacer(),
              Text(
                (schedule.room?.isNotEmpty == true) ? schedule.room! : '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subject.subjectName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _buildSubtitle(schedule),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 18,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatRange(start, end),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onStartSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(hasOngoing ? 'Resume Session' : 'Start Session'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(Schedule s) {
    final hasRoom = s.room?.isNotEmpty == true;
    final roomText = hasRoom ? 'Room ${s.room}' : '';
    // Placeholder students count to match the reference UI
    final students = '• 28 students';
    if (roomText.isEmpty) return students.replaceFirst('• ', '');
    return '$roomText $students';
  }

  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '';
    final f = DateFormat('h:mm a');
    return '${f.format(start)} - ${f.format(end)}';
  }
}

// Removed Avatar widget as avatars are not shown in the new design
