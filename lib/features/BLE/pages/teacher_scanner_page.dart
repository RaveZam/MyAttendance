import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:myattendance/core/database/app_database.dart';

class TeacherScannerPage extends StatefulWidget {
  final String qrPayload;
  final List<Student> students;
  final List<AttendanceData> attendanceList;
  final VoidCallback loadAttendance;
  final String sessionRecordId;

  const TeacherScannerPage({
    super.key,
    required this.qrPayload,
    required this.students,
    required this.attendanceList,
    required this.loadAttendance,
    required this.sessionRecordId,
  });

  @override
  State<TeacherScannerPage> createState() => _TeacherScannerPageState();
}

class StudentData {
  final String studentId;
  final String studentName;

  StudentData({required this.studentId, required this.studentName});
  @override
  String toString() {
    return 'StudentData(studentId: $studentId, studentName: $studentName)';
  }
}

class _TeacherScannerPageState extends State<TeacherScannerPage> {
  late final String sessionId;
  late final String classCode;
  late final int sessionDbId;

  final List<StudentData> studentData = [];
  final Set<String> _processedStudentIds = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    final classData = jsonDecode(widget.qrPayload);
    sessionId = classData['class_session_id'];
    classCode = classData['class_code'];
    sessionDbId = int.tryParse(widget.sessionRecordId) ?? -1;

    _scanForStudents();
  }

  void _scanForStudents() async {
    var subscription = FlutterBluePlus.onScanResults.listen((results) async {
      if (results.isEmpty || _isProcessing) return;

      final lastResult = results.last;
      if (lastResult.advertisementData.manufacturerData.isEmpty) return;

      final entry = lastResult.advertisementData.manufacturerData.entries.first;
      final rawData = Uint8List.fromList(entry.value);
      final decoded = String.fromCharCodes(rawData);

      await _handlePayload(decoded);
    });

    FlutterBluePlus.cancelWhenScanComplete(subscription);

    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first;

    await FlutterBluePlus.startScan(); // keep scanning until stopped
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan(); // stop scan when leaving
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.bluetooth_searching, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              "Scanning for students...",
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Detected: ${studentData.length}",
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: studentData.length,
            itemBuilder: (context, index) {
              final student = studentData[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      student.studentName.isNotEmpty
                          ? student.studentName[0].toUpperCase()
                          : "?",
                    ),
                  ),
                  title: Text(student.studentName),
                  subtitle: Text(student.studentId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _handlePayload(String payload) async {
    if (!payload.startsWith("STUDENT:")) return;

    final parsed = _parsePayload(payload);
    final studentId = parsed['STUDENT'];
    final studentName = parsed['NAME'] ?? 'Unknown';
    final session = parsed['SESSION'];
    final code = parsed['CLASS'];

    if (studentId == null ||
        session == null ||
        code == null ||
        session != sessionId ||
        code != classCode) {
      return;
    }

    if (_processedStudentIds.contains(studentId)) return;

    final alreadyRecorded = widget.attendanceList.any(
      (attendance) => attendance.studentId == studentId,
    );
    if (alreadyRecorded) {
      _processedStudentIds.add(studentId);
      return;
    }

    final isEnrolled = widget.students.any(
      (student) => student.studentId == studentId,
    );

    if (!isEnrolled) {
      _processedStudentIds.add(studentId);
      _showSnack(
        "Student $studentId is not enrolled in this class",
        Colors.orange,
      );
      return;
    }

    if (sessionDbId == -1) {
      _showSnack("Invalid session information", Colors.red);
      return;
    }

    _isProcessing = true;
    try {
      // Determine if attendance should be marked as late
      final session = await AppDatabase.instance.getSessionById(sessionDbId);
      String status = 'present';
      
      if (session != null) {
        final subjects = await AppDatabase.instance.getSubjectByID(session.subjectId);
        if (subjects.isNotEmpty) {
          final subject = subjects.first;
          final attendanceTime = DateTime.now();
          final sessionStartTime = session.startTime;
          final lateAfterMinutes = subject.lateAfterMinutes;
          final lateThreshold = sessionStartTime.add(Duration(minutes: lateAfterMinutes));
          
          if (attendanceTime.isAfter(lateThreshold)) {
            status = 'late';
          }
        }
      }

      await AppDatabase.instance.insertAttendance(
        AttendanceCompanion.insert(
          studentId: studentId,
          sessionId: sessionDbId,
          status: status,
          synced: false,
        ),
      );

      widget.loadAttendance();
      setState(() {
        studentData.add(
          StudentData(studentId: studentId, studentName: studentName),
        );
        _processedStudentIds.add(studentId);
      });

      _showSnack(
        status == 'late' 
            ? "Marked $studentName as late" 
            : "Marked $studentName as present",
        status == 'late' ? Colors.orange : Colors.green,
      );
    } catch (e) {
      debugPrint('Error inserting BLE attendance: $e');
      _showSnack("Failed to mark $studentName", Colors.red);
    } finally {
      _isProcessing = false;
    }
  }

  Map<String, String> _parsePayload(String payload) {
    final parts = payload.split("|");
    final parsed = <String, String>{};
    for (final part in parts) {
      final splitIndex = part.indexOf(":");
      if (splitIndex == -1) continue;
      final key = part.substring(0, splitIndex);
      final value = part.substring(splitIndex + 1);
      parsed[key] = value;
    }
    return parsed;
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }
}
