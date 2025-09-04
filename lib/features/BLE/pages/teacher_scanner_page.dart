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

class _TeacherScannerPageState extends State<TeacherScannerPage> {
  late final String sessionId;
  late final String classCode;

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

            debugPrint(
              "🎓 Student $studentId joined $classCode - $sessionId ✅",
            );
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
    return const Center(child: Text("📡 Scanning for students..."));
  }
}
