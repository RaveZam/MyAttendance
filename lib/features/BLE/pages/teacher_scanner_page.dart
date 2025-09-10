import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class TeacherScannerPage extends StatefulWidget {
  final String qrPayload;

  const TeacherScannerPage({super.key, required this.qrPayload});

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

  var studentData = [];

  @override
  void initState() {
    super.initState();

    final classData = jsonDecode(widget.qrPayload);
    sessionId = classData['class_session_id'];
    classCode = classData['class_code'];

    _scanForStudents();
  }

  void _scanForStudents() async {
    var subscription = FlutterBluePlus.onScanResults.listen((results) {
      if (results.isNotEmpty) {
        ScanResult r = results.last;

        if (r.advertisementData.manufacturerData.isNotEmpty) {
          final entry = r.advertisementData.manufacturerData.entries.first;
          final rawData = Uint8List.fromList(entry.value);
          final decoded = String.fromCharCodes(rawData);

          // check for student payload with session + class
          if (decoded.startsWith("STUDENT:") &&
              decoded.contains("SESSION:$sessionId") &&
              decoded.contains("CLASS:$classCode")) {
            final parts = decoded.split("|");
            final studentId = parts[0].replaceFirst("STUDENT:", "");
            final studentName = parts[1].replaceFirst("NAME:", "");

            bool studentExists = studentData.any(
              (student) => student.studentId == studentId,
            );

            if (studentExists) {
              debugPrint("Student $studentId already exists");
              return;
            } else {
              setState(() {
                studentData.add(
                  StudentData(studentId: studentId, studentName: studentName),
                );
              });

              debugPrint(
                "🎓 Student $studentId joined $classCode - $sessionId ✅",
              );
              debugPrint("studentData: $studentData");
            }
          }
        }
      }
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
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Text("📡 Scanning for students..."),
          Text("Attendees: ${studentData.length}"),

          Expanded(
            child: ListView.builder(
              itemCount: studentData.length,
              itemBuilder: (context, index) {
                final student = studentData[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(student.studentName[0])),
                  title: Text(student.studentName),
                  subtitle: Text(student.studentId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
