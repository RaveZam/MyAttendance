import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/features/QRFeature/widgets/teacher_qr_reader.dart';
import 'package:myattendance/features/Teacher/features/attendance/widgets/attendance_list.dart';

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

  @override
  void initState() {
    super.initState();
    _getSubjectDetails();
    getSessionDetails();
    _loadStudents();
    _loadAttendance();
    // AppDatabase.instance.clearAttendanceSession();
  }

  void _loadAttendance() async {
    final attendance = await AppDatabase.instance.getAttendanceBySessionID(
      int.parse(widget.sessionID),
    );
    setState(() {
      _attendance = attendance;
    });
  }

  void getSessionDetails() async {
    final sessions = await AppDatabase.instance.getSessionByID(
      int.parse(widget.sessionID),
    );
    if (sessions.isNotEmpty) {
      setState(() {
        sessionDetails = sessions.first;
      });
      debugPrint('Session loaded: $sessionDetails');
    }
  }

  void _getSubjectDetails() async {
    debugPrint('AttendancePage: fetching subject ${widget.subjectId}');
    try {
      final subjects = await AppDatabase.instance.getSubjectByID(
        int.parse(widget.subjectId),
      );

      if (subjects.isNotEmpty) {
        setState(() {
          subjectDetails = subjects.first;
        });
        debugPrint('Subject loaded: ${subjectDetails?.subjectName}');
      } else {
        setState(() {
          subjectDetails = null;
        });
        debugPrint('No subject found with ID: ${widget.subjectId}');
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
                          Text(
                            'Select Student',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Student>(
                        value: _selectedStudent,
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
                                  ),
                                ),
                              ]
                            : _students.map((Student student) {
                                return DropdownMenuItem<Student>(
                                  value: student,
                                  child: Text(
                                    '${student.firstName} ${student.lastName} (${student.studentId})',
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
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Current Session summary (always visible)
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
                    const Text(
                      'Current Session',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _StatItem(label: 'Present', value: '24'),
                        _StatItem(label: 'Absent', value: '6'),
                        _StatItem(label: 'Total', value: '30'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Recent Check-ins header (we'll not include the students list per request)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Check-ins',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  TextButton(onPressed: () {}, child: const Text('View All')),
                ],
              ),
              const SizedBox(height: 8),

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
                    onPressed: () {},
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

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
