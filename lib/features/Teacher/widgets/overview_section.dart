import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';

class OverviewSection extends StatefulWidget {
  const OverviewSection({super.key});

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  int _classesCount = 0;
  String _attendancePercentage = '0%';
  int _studentsCount = 0;
  int _presentCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayData();
  }

  Future<void> _loadTodayData() async {
    setState(() => _loading = true);
    try {
      final db = AppDatabase.instance;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Get all sessions
      final allSessions = await (db.select(db.sessions)).get();

      // Filter sessions for today
      final todaySessions = allSessions.where((session) {
        final sessionDate = session.startTime;
        return sessionDate.isAfter(
              todayStart.subtract(const Duration(seconds: 1)),
            ) &&
            sessionDate.isBefore(todayEnd.add(const Duration(seconds: 1)));
      }).toList();

      _classesCount = todaySessions.length;

      // Get all session IDs for today
      final todaySessionIds = todaySessions.map((s) => s.id).toList();

      // Get all attendance records for today's sessions
      List<AttendanceData> todayAttendance = [];
      if (todaySessionIds.isNotEmpty) {
        todayAttendance = await db.getAttendanceBySessionIds(todaySessionIds);
      }

      // Count present students
      _presentCount = todayAttendance
          .where((a) => a.status.toLowerCase() == 'present')
          .length;

      // Get all unique students across all subjects
      final allSubjects = await db.getAllSubjects();
      Set<int> uniqueStudentIds = {};
      for (final subject in allSubjects) {
        final students = await db.getStudentsInSubject(subject.id);
        for (final student in students) {
          uniqueStudentIds.add(student.id);
        }
      }
      _studentsCount = uniqueStudentIds.length;

      // Calculate attendance percentage based on actual expected attendance
      // For each session today, count students enrolled in that subject
      int totalExpectedAttendance = 0;

      for (final session in todaySessions) {
        final students = await db.getStudentsInSubject(session.subjectId);
        totalExpectedAttendance += students.length;
      }

      if (totalExpectedAttendance > 0) {
        final percentage = (_presentCount / totalExpectedAttendance * 100)
            .round();
        _attendancePercentage = '$percentage%';
      } else {
        _attendancePercentage = '0%';
      }
    } catch (e) {
      debugPrint('Error loading today data: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's Overview",
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.today, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Today',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _CompactStatCard(
                          icon: Icons.calendar_today,
                          iconColor: Color(0xFF2563EB),
                          label: 'Classes Conducted',
                          value: _classesCount.toString(),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _CompactStatCard(
                          icon: Icons.insights,
                          iconColor: Color(0xFF10B981),
                          label: 'Attendance',
                          value: _attendancePercentage,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _CompactStatCard(
                          icon: Icons.groups,
                          iconColor: Color(0xFF059669),
                          label: 'Students',
                          value: _studentsCount.toString(),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _CompactStatCard(
                          icon: Icons.verified,
                          iconColor: Color(0xFFF59E0B),
                          label: 'Present',
                          value: _presentCount.toString(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _CompactStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
