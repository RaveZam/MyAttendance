import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/core/database/app_database.dart';

class AttendancePerSessionPage extends StatefulWidget {
  final String sessionId;

  const AttendancePerSessionPage({super.key, required this.sessionId});

  @override
  State<AttendancePerSessionPage> createState() =>
      _AttendancePerSessionPageState();
}

class _AttendancePerSessionPageState extends State<AttendancePerSessionPage> {
  final db = AppDatabase.instance;
  bool _loading = true;
  List<AttendanceData> _attendances = [];
  List<Student> _enrolledStudents = [];
  List<Student> _absentStudents = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    debugPrint(
      '🔄 [ATTENDANCE LOADING] Loading attendance for session ID: ${widget.sessionId}',
    );
    setState(() => _loading = true);
    try {
      final session = await db.getSessionById(int.parse(widget.sessionId));
      if (session == null) {
        debugPrint('❌ [ATTENDANCE LOADING] Session not found');
        return;
      }

      debugPrint(
        '📊 [SESSION INFO] Session: ${session.id}, Status: ${session.status}',
      );
      debugPrint('   📅 Start: ${session.startTime.toIso8601String()}');
      debugPrint('   📅 End: ${session.endTime?.toIso8601String() ?? 'null'}');
      debugPrint('   🏫 Subject ID: ${session.subjectId}');

      // Get all enrolled students for this subject
      final enrolledStudents = await db.getStudentsInSubject(session.subjectId);
      debugPrint(
        '👥 [ENROLLED STUDENTS] Found ${enrolledStudents.length} enrolled students',
      );

      // Get attendance records for this session
      final attendanceList = await db.getAttendanceBySessionID(
        int.parse(widget.sessionId),
      );
      debugPrint(
        '📋 [ATTENDANCE RECORDS] Found ${attendanceList.length} attendance records',
      );

      // Filter present students
      final presentAttendances = attendanceList
          .where((a) => a.status.toLowerCase() == 'present')
          .toList();
      presentAttendances.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Filter absent students from attendance records
      final absentAttendances = attendanceList
          .where((a) => a.status.toLowerCase() == 'absent')
          .toList();

      debugPrint(
        '✅ [PRESENT STUDENTS] Found ${presentAttendances.length} present students',
      );
      debugPrint(
        '❌ [ABSENT STUDENTS] Found ${absentAttendances.length} absent students',
      );

      // Log each attendance record
      for (var attendance in attendanceList) {
        debugPrint(
          '   📝 Attendance ${attendance.id}: Student ${attendance.studentId} - ${attendance.status}',
        );
        debugPrint(
          '      📅 Created: ${attendance.createdAt.toIso8601String()}',
        );
        if (attendance.lastModified != null) {
          debugPrint(
            '      🔄 Last Modified: ${attendance.lastModified!.toIso8601String()}',
          );
        }
      }

      // Create a map of studentId to attendance record for efficient lookup
      final absentAttendanceMap = {
        for (var record in absentAttendances) record.studentId: record
      };

      // Find students who have absent attendance records
      final absentStudents = enrolledStudents
          .where((student) => absentAttendanceMap.containsKey(student.studentId))
          .toList();

      // Sort absent students by their attendance record creation time
      absentStudents.sort((a, b) {
        final aRecord = absentAttendanceMap[a.studentId]!;
        final bRecord = absentAttendanceMap[b.studentId]!;
        return bRecord.createdAt.compareTo(aRecord.createdAt);
      });

      for (var student in absentStudents) {
        debugPrint(
          '   👤 Absent: ${student.firstName} ${student.lastName} (${student.studentId})',
        );
      }

      setState(() {
        _enrolledStudents = enrolledStudents;
        _attendances = presentAttendances;
        _absentStudents = absentStudents;
      });

      debugPrint('✅ [ATTENDANCE LOADING] Attendance data loaded successfully');
    } catch (e) {
      debugPrint('❌ [ATTENDANCE LOADING] Failed to load attendance: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Attendance',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: scheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadAttendance,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _buildSummaryRow(scheme),
                  const SizedBox(height: 20),

                  // Present List
                  Text(
                    'Present (${_attendances.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._attendances.map((a) => _AttendanceTile(data: a)).toList(),

                  const SizedBox(height: 20),

                  // Absent List
                  Text(
                    'Absent (${_absentStudents.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._absentStudents
                      .map((student) => _AbsentStudentTile(student: student))
                      .toList(),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryRow(ColorScheme scheme) {
    final present = _attendances.length;
    final absent = _absentStudents.length;
    final total = _enrolledStudents.length;
    return Row(
      children: [
        _summaryBox(scheme, present.toString(), 'Present'),
        const SizedBox(width: 12),
        _summaryBox(scheme, absent.toString(), 'Absent'),
        const SizedBox(width: 12),
        _summaryBox(scheme, total.toString(), 'Total'),
      ],
    );
  }

  Widget _summaryBox(ColorScheme scheme, String value, String label) {
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final AttendanceData data;
  const _AttendanceTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = DateFormat('h:mm a').format(data.createdAt.toLocal());
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${data.studentId}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Present',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Present',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbsentStudentTile extends StatelessWidget {
  final Student student;
  const _AbsentStudentTile({required this.student});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person_off, color: Colors.red.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${student.studentId}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${student.firstName} ${student.lastName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Absent',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
