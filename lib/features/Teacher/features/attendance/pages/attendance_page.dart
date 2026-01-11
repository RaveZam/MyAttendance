import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/features/BLE/pages/teacher_scanner_page.dart';
import 'package:myattendance/features/QRFeature/widgets/qrcode.dart';
import 'package:myattendance/features/QRFeature/widgets/teacher_qr_reader.dart';
import 'package:myattendance/features/Teacher/features/attendance/widgets/attendance_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

class AttendancePage extends StatefulWidget {
  final String subjectId;
  final String sessionID;

  const AttendancePage({
    super.key,
    required this.subjectId,
    required this.sessionID,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Subject? subjectDetails;
  Session? sessionDetails;

  // UI State Management
  String _selectedMethod = ''; // 'qr' or 'manual'
  List<Student> _students = [];
  Student? _selectedStudent;
  final GlobalKey<TeacherQrReaderState> _qrReaderKey =
      GlobalKey<TeacherQrReaderState>();

  List<AttendanceData> _attendance = [];
  bool _isResumingSession = false;
  String _instructorName = '';

  @override
  void initState() {
    super.initState();
    getSessionDetails();
    _loadStudents();
    _loadAttendance();
    _checkIfResumingSession();
    _loadInstructorName();
  }

  void _loadInstructorName() {
    final user = supa.Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    final firstName = (user.userMetadata?['first_name'] ?? '').toString();
    final lastName = (user.userMetadata?['last_name'] ?? '').toString();
    final fullName = '$firstName $lastName'.trim();
    setState(() {
      _instructorName = fullName.isEmpty ? 'Instructor' : fullName;
    });
  }

  void _checkIfResumingSession() async {
    // Check if there are existing attendance records for this session
    final existingAttendance = await AppDatabase.instance
        .getAttendanceBySessionID(int.parse(widget.sessionID));

    setState(() {
      _isResumingSession = existingAttendance.isNotEmpty;
    });
  }

  void _loadAttendance() async {
    debugPrint(
      '🔄 [ATTENDANCE LOADING] Loading attendance for session ID: ${widget.sessionID}',
    );
    final attendance = await AppDatabase.instance.getAttendanceBySessionID(
      int.parse(widget.sessionID),
    );
    debugPrint(
      '📋 [ATTENDANCE RECORDS] Found ${attendance.length} attendance records',
    );

    // Check and update attendance records for late status
    if (sessionDetails != null && subjectDetails != null) {
      await _checkAndUpdateLateAttendance(attendance);
      // Reload attendance after updates
      final updatedAttendance = await AppDatabase.instance.getAttendanceBySessionID(
        int.parse(widget.sessionID),
      );
      setState(() {
        _attendance = updatedAttendance;
      });
    } else {
      setState(() {
        _attendance = attendance;
      });
    }

    // Log each attendance record
    for (var record in _attendance) {
      debugPrint(
        '   📝 Attendance ${record.id}: Student ${record.studentId} - ${record.status}',
      );
      debugPrint('      📅 Created: ${record.createdAt.toIso8601String()}');
      debugPrint(
        '      🔄 Last Modified: ${record.lastModified.toIso8601String()}',
      );
    }

    debugPrint('✅ [ATTENDANCE LOADING] Attendance data loaded successfully');
  }

  /// Checks if attendance should be marked as late based on session start time and lateAfterMinutes
  bool _isAttendanceLate(DateTime attendanceTime, DateTime sessionStartTime, int lateAfterMinutes) {
    final lateThreshold = sessionStartTime.add(Duration(minutes: lateAfterMinutes));
    return attendanceTime.isAfter(lateThreshold);
  }

  /// Checks existing attendance records and updates them to "late" if they exceed the late threshold
  Future<void> _checkAndUpdateLateAttendance(List<AttendanceData> attendance) async {
    if (sessionDetails == null || subjectDetails == null) return;

    final sessionStartTime = sessionDetails!.startTime;
    final lateAfterMinutes = subjectDetails!.lateAfterMinutes;
    final db = AppDatabase.instance;

    for (var record in attendance) {
      // Only check records that are currently marked as "present"
      if (record.status.toLowerCase() == 'present') {
        final isLate = _isAttendanceLate(
          record.createdAt,
          sessionStartTime,
          lateAfterMinutes,
        );

        if (isLate) {
          debugPrint(
            '⏰ [LATE CHECK] Updating attendance ${record.id} for student ${record.studentId} from present to late',
          );
          try {
            await (db.update(db.attendance)
                  ..where((t) => t.id.equals(record.id)))
                .write(
              AttendanceCompanion(
                status: const Value('late'),
                lastModified: Value(DateTime.now()),
                synced: const Value(false),
              ),
            );
          } catch (e) {
            debugPrint('❌ [LATE CHECK] Error updating attendance ${record.id}: $e');
          }
        }
      }
    }
  }

  /// Determines the attendance status (present or late) based on current time
  String _determineAttendanceStatus(DateTime attendanceTime) {
    if (sessionDetails == null || subjectDetails == null) {
      return 'present';
    }

    final sessionStartTime = sessionDetails!.startTime;
    final lateAfterMinutes = subjectDetails!.lateAfterMinutes;

    if (_isAttendanceLate(attendanceTime, sessionStartTime, lateAfterMinutes)) {
      return 'late';
    }
    return 'present';
  }

  void getSessionDetails() async {
    final sessionId = int.tryParse(widget.sessionID);
    if (sessionId == null) {
      _loadSubjectDetails(int.tryParse(widget.subjectId));
      return;
    }

    final sessions = await AppDatabase.instance.getSessionByID(sessionId);
    if (sessions.isNotEmpty) {
      final session = sessions.first;
      setState(() {
        sessionDetails = session;
      });
      debugPrint('Session loaded: $sessionDetails');
      _loadSubjectDetails(session.subjectId);
    } else {
      _loadSubjectDetails(int.tryParse(widget.subjectId));
    }
  }

  Future<void> _loadSubjectDetails(int? subjectId) async {
    if (subjectId == null) return;

    debugPrint('AttendancePage: fetching subject $subjectId');
    try {
      final subjects = await AppDatabase.instance.getSubjectByID(subjectId);

      if (subjects.isNotEmpty) {
        setState(() {
          subjectDetails = subjects.first;
        });
        debugPrint('Subject loaded: ${subjectDetails?.subjectName}');
      } else {
        setState(() {
          subjectDetails = null;
        });
        debugPrint('No subject found with ID: $subjectId');
      }
    } catch (e) {
      debugPrint('Error loading subject details: $e');
      setState(() {
        subjectDetails = null;
      });
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not available';

    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final date = dateFormat.format(dateTime);
    final time = timeFormat.format(dateTime);

    return '$date at $time';
  }

  void _loadStudents() async {
    try {
      final students = await AppDatabase.instance.getStudentsInSubject(
        int.parse(widget.subjectId),
      );
      setState(() {
        _students = students;
      });
    } catch (e) {
      debugPrint('Error loading students: $e');
    }
  }

  void _selectMethod(String method) {
    setState(() {
      _selectedMethod = method;
    });
  }

  void _goBack() {
    setState(() {
      _selectedMethod = '';
      _selectedStudent = null;
    });
  }

  void finishSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Session?'),
        content: Text(
          'Are you sure you want to end this session?\n\n'
          'This will mark the session as completed and you won\'t be able to add more attendance records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = AppDatabase.instance;
        final sessionId = int.parse(widget.sessionID);

        // Get session details to get subjectId
        final session = await db.getSessionById(sessionId);
        if (session == null) {
          throw Exception('Session not found');
        }

        // Get all enrolled students for this subject
        final enrolledStudents = await db.getStudentsInSubject(
          session.subjectId,
        );

        // Get all existing attendance records for this session
        final existingAttendance = await db.getAttendanceBySessionID(sessionId);

        // Get student IDs who already have attendance records
        final studentsWithAttendance = existingAttendance
            .map((a) => a.studentId)
            .toSet();

        // Find students who don't have attendance records yet
        final absentStudents = enrolledStudents
            .where(
              (student) => !studentsWithAttendance.contains(student.studentId),
            )
            .toList();

        // Create "absent" attendance records for students without records
        if (absentStudents.isNotEmpty) {
          debugPrint(
            '📝 [FINISH SESSION] Creating absent records for ${absentStudents.length} students',
          );

          for (var student in absentStudents) {
            try {
              await db.insertAttendance(
                AttendanceCompanion.insert(
                  studentId: student.studentId,
                  sessionId: sessionId,
                  status: 'absent',
                  synced: false,
                ),
              );
              debugPrint(
                '   ✅ Marked ${student.firstName} ${student.lastName} (${student.studentId}) as absent',
              );
            } catch (e) {
              debugPrint(
                '   ❌ Failed to mark ${student.studentId} as absent: $e',
              );
            }
          }
        }

        // Now finish the session
        await db.finishSession(sessionId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                absentStudents.isNotEmpty
                    ? 'Session ended. ${absentStudents.length} students marked as absent.'
                    : 'Session ended successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, 'session_ended');
        }
      } catch (e) {
        debugPrint('❌ [FINISH SESSION] Error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to end session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // List<AttendanceData> _attendanceList = [];

  // void loadAttendance() async {
  //   final attendance = await AppDatabase.instance.getAttendanceBySessionID(
  //     int.parse(widget.sessionID),
  //   );
  //   setState(() {
  //     _attendance = attendance;
  //   });
  // }

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
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: scheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      backgroundColor: scheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectDetails != null
                          ? '${subjectDetails!.subjectName} (${subjectDetails!.subjectCode})'
                          : 'Loading subject...',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subjectDetails != null
                          ? 'Year ${subjectDetails!.yearLevel} · ${subjectDetails!.section} · Subject ID: ${subjectDetails!.id}'
                          : 'Subject ID: ${widget.subjectId} · Loading schedule...',
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Session ${sessionDetails?.status}',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Session Started On: ${_formatDateTime(sessionDetails?.startTime)}',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    if (subjectDetails != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Late After: ${subjectDetails!.lateAfterMinutes} ${subjectDetails!.lateAfterMinutes == 1 ? 'minute' : 'minutes'}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_isResumingSession) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'RESUMED SESSION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Conditional content based on selected method
              if (_selectedMethod.isEmpty) ...[
                // Select Attendance Method
                Text(
                  'Select Attendance Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _MethodCard(
                      icon: Icons.qr_code_2,
                      title: 'Scan QR Code',
                      subtitle: 'Students scan QR code to mark attendance',
                      onTap: () => _selectMethod('qr'),
                    ),
                    const SizedBox(height: 12),
                    _MethodCard(
                      icon: Icons.keyboard,
                      title: 'Manual Input',
                      subtitle: 'Manually enter student ID numbers',
                      onTap: () => _selectMethod('manual'),
                    ),
                    const SizedBox(height: 12),
                    _MethodCard(
                      icon: Icons.bluetooth_connected,
                      title: 'BLE Broadcast',
                      subtitle: 'Students scan class QR then broadcast via BLE',
                      onTap: () => _selectMethod('ble'),
                    ),
                  ],
                ),
              ] else if (_selectedMethod == 'qr') ...[
                // QR Code Scanner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _goBack,
                            icon: const Icon(Icons.arrow_back),
                            style: IconButton.styleFrom(
                              backgroundColor: scheme.surface,
                              foregroundColor: scheme.onSurface,
                            ),
                          ),

                          Text(
                            'Scan QR Code',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TeacherQrReader(
                        students: _students,
                        attendanceList: _attendance,
                        loadAttendance: _loadAttendance,
                        key: _qrReaderKey,
                        sessionID: widget.sessionID,
                        onQRCodeDetected: (qrData) {
                          debugPrint('QR Code detected: $qrData');
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Position the QR code within the frame to scan',
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // ElevatedButton.icon(
                      //   onPressed: () {
                      //     _qrReaderKey.currentState?.resetScanner();
                      //   },
                      //   icon: const Icon(Icons.refresh),
                      //   label: const Text('Scan Another QR Code'),
                      //   style: ElevatedButton.styleFrom(
                      //     backgroundColor: scheme.primary,
                      //     foregroundColor: scheme.onPrimary,
                      //     padding: const EdgeInsets.symmetric(
                      //       horizontal: 20,
                      //       vertical: 12,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ] else if (_selectedMethod == 'ble') ...[
                _buildBleMethodCard(scheme),
              ] else if (_selectedMethod == 'manual') ...[
                // Manual Input
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: _goBack,
                            icon: const Icon(Icons.arrow_back),
                            style: IconButton.styleFrom(
                              backgroundColor: scheme.surface,
                              foregroundColor: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Select Student',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Student>(
                        value: _selectedStudent,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: _students.isEmpty
                              ? 'Loading students...'
                              : 'Choose a student',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        items: _students.isEmpty
                            ? [
                                DropdownMenuItem<Student>(
                                  value: null,
                                  child: Text(
                                    'No students found',
                                    style: TextStyle(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]
                            : _students.map((Student student) {
                                return DropdownMenuItem<Student>(
                                  value: student,
                                  child: Text(
                                    '${student.firstName} ${student.lastName} (${student.studentId})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                        onChanged: _students.isEmpty
                            ? null
                            : (Student? newValue) {
                                setState(() {
                                  _selectedStudent = newValue;
                                });
                              },
                      ),
                      if (_selectedStudent != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: scheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Selected: ${_selectedStudent!.firstName} ${_selectedStudent!.lastName}',
                                  style: TextStyle(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () async {
                              if (_selectedStudent == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select a student first.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final alreadyRecorded = _attendance.any(
                                (a) =>
                                    a.studentId == _selectedStudent!.studentId,
                              );

                              if (alreadyRecorded) {
                                final existingRecord = _attendance.firstWhere(
                                  (a) => a.studentId == _selectedStudent!.studentId,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'This student is already marked as ${existingRecord.status}.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                final attendanceTime = DateTime.now();
                                final status = _determineAttendanceStatus(attendanceTime);

                                await AppDatabase.instance.insertAttendance(
                                  AttendanceCompanion.insert(
                                    studentId: _selectedStudent!.studentId,
                                    sessionId: int.parse(widget.sessionID),
                                    status: status,
                                    synced: false,
                                  ),
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        status == 'late'
                                            ? 'Marked ${_selectedStudent!.firstName} ${_selectedStudent!.lastName} as late.'
                                            : 'Marked ${_selectedStudent!.firstName} ${_selectedStudent!.lastName} as present.',
                                      ),
                                      backgroundColor: status == 'late' ? Colors.orange : Colors.green,
                                    ),
                                  );
                                }

                                // Refresh attendance summary and list
                                _loadAttendance();
                              } catch (e) {
                                debugPrint(
                                  'Error marking student as present manually: $e',
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to mark student as present.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              'Mark As Present',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Current Session summary (always visible)
              Builder(
                builder: (context) {
                  // Calculate present students
                  final presentCount = _attendance
                      .where((a) => a.status.toLowerCase() == 'present')
                      .length;

                  // Calculate late students
                  final lateCount = _attendance
                      .where((a) => a.status.toLowerCase() == 'late')
                      .length;

                  // Calculate pending students (total enrolled - students with attendance records)
                  final studentsWithAttendance = _attendance
                      .map((a) => a.studentId)
                      .toSet();
                  final pendingCount = _students
                      .where(
                        (student) =>
                            !studentsWithAttendance.contains(student.studentId),
                      )
                      .length;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Session',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatItem(
                              label: 'Present',
                              value: presentCount.toString(),
                              textColor: Colors.green.shade800,
                            ),
                            _StatItem(
                              label: 'Late',
                              value: lateCount.toString(),
                              textColor: Colors.orange.shade700,
                            ),
                            _StatItem(
                              label: 'Pending',
                              value: pendingCount.toString(),
                              textColor: scheme.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              AttendanceList(
                sessionID: widget.sessionID,
                attendanceList: _attendance,
              ),
              const SizedBox(height: 12),

              // Buttons (always visible)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary.withValues(alpha: 0.95),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      finishSession();
                    },
                    child: Text(
                      'End Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: scheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: scheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Export Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBleMethodCard(ColorScheme scheme) {
    final classData = _buildBleClassData();
    final qrPayload = jsonEncode(classData);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: scheme.surface,
                  foregroundColor: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'BLE Attendance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Qrcode(classData: classData),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bluetooth_searching,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Scanner",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Keep this screen open so nearby students can broadcast their '
                  'attendance after scanning your class QR.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 320,
                  child: TeacherScannerPage(
                    qrPayload: qrPayload,
                    students: _students,
                    attendanceList: _attendance,
                    loadAttendance: _loadAttendance,
                    sessionRecordId: widget.sessionID,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildBleClassData() {
    final subject = subjectDetails;
    final session = sessionDetails;
    final sessionStart = session?.startTime;
    final sessionEnd = session?.endTime;
    final day = sessionStart != null
        ? DateFormat('EEEE').format(sessionStart)
        : '';
    final timeFormat = DateFormat('h:mm a');

    final startTime = sessionStart != null
        ? timeFormat.format(sessionStart)
        : '-';
    final endTime = sessionEnd != null ? timeFormat.format(sessionEnd) : '';

    final sessionIdentifier = (sessionDetails?.supabaseId ?? '').isNotEmpty
        ? sessionDetails!.supabaseId!
        : widget.sessionID;

    return {
      "class_code": subject?.subjectCode ?? 'CLASS',
      "class_name": subject?.subjectName ?? 'Class',
      "section": subject?.section ?? '',
      "year_level": subject?.yearLevel ?? '',
      "class_session_id": sessionIdentifier,
      "instructor_name": _instructorName,
      "start_time": startTime,
      "end_time": endTime.isEmpty ? '-' : endTime,
      "day": day,
    };
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _MethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 28, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? textColor;

  const _StatItem({required this.label, required this.value, this.textColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueColor = textColor ?? scheme.onSurface;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor ?? scheme.onSurface.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
