import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:myattendance/features/QRFeature/widgets/custom_border_painter.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';

class StudentQrReader extends StatefulWidget {
  final String subjectId;
  final VoidCallback? onStudentAdded;

  const StudentQrReader({
    super.key,
    required this.subjectId,
    this.onStudentAdded,
  });

  @override
  State<StudentQrReader> createState() => StudentQrReaderState();
}

class StudentQrReaderState extends State<StudentQrReader> {
  final MobileScannerController controller = MobileScannerController();
  bool _hasScanned = false;
  bool _isProcessing = false;
  DateTime? _lastScanAt;
  String? _lastScannedId;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Rect scanWindow = const Rect.fromLTWH(0, 0, 250, 250);

    return SizedBox(
      height: 250,
      width: 250,
      child: Stack(
        children: [
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: (capture) async {
              // Prevent processing if already processing or recently scanned
              if (_isProcessing) {
                debugPrint('Already processing a scan');
                return;
              }

              final now = DateTime.now();

              // Debounce: only process if enough time has passed since last scan
              if (_lastScanAt != null &&
                  now.difference(_lastScanAt!).inMilliseconds < 2000) {
                debugPrint('Debounced - too soon after last scan');
                return;
              }

              final rawQr = capture.barcodes.first.rawValue;
              if (rawQr == null) return;

              // Check if this is the same QR code as last time
              if (_lastScannedId == rawQr) {
                debugPrint('Same QR code as last scan - ignoring');
                return;
              }

              _isProcessing = true;
              _lastScanAt = now;
              _lastScannedId = rawQr;

              try {
                final Map<String, dynamic> data = jsonDecode(rawQr);
                debugPrint("QR code detected: $data");

                // Validate required fields
                final firstName = data['first_name']?.toString();
                final lastName = data['last_name']?.toString();
                final studentId = data['student_id']?.toString();

                if (firstName == null ||
                    lastName == null ||
                    studentId == null ||
                    firstName.isEmpty ||
                    lastName.isEmpty ||
                    studentId.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Invalid QR Code: Missing required fields',
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  _isProcessing = false;
                  return;
                }

                // Show success overlay
                setState(() {
                  _hasScanned = true;
                });

                // Handle student insertion directly
                await _handleStudentInsertion(
                  firstName: firstName,
                  lastName: lastName,
                  studentId: studentId,
                );

                // Reset overlay after delay
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (!mounted) return;
                  setState(() {
                    _hasScanned = false;
                    _isProcessing = false;
                  });
                });
              } catch (e) {
                debugPrint('Error parsing QR code: $e');
                _isProcessing = false;
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error parsing QR code: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          CustomPaint(
            painter: CornerBorderPainter(scanWindow: scanWindow),
            size: Size.infinite,
          ),
          // Success overlay
          if (_hasScanned)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'QR Code Scanned!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Method to reset the scanner
  void resetScanner() {
    setState(() {
      _hasScanned = false;
    });
  }

  Future<void> _handleStudentInsertion({
    required String firstName,
    required String lastName,
    required String studentId,
  }) async {
    try {
      // Trim and validate inputs
      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();
      final trimmedStudentId = studentId.trim();

      debugPrint(
        "[StudentQrReader] attempting to insert student "
        "$trimmedFirstName $trimmedLastName ($trimmedStudentId)",
      );

      // Validate that all fields are not empty
      if (trimmedFirstName.isEmpty ||
          trimmedLastName.isEmpty ||
          trimmedStudentId.isEmpty) {
        debugPrint("[StudentQrReader] validation failed: empty field(s)");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("All fields are required!"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      debugPrint(
        "[StudentQrReader] checking for duplicate student ID in subject "
        "${widget.subjectId}: '$trimmedStudentId'",
      );

      // Debug: Get students in this subject to see what's enrolled
      final subjectStudents = await AppDatabase.instance.getStudentsInSubject(
        int.parse(widget.subjectId),
      );
      debugPrint(
        "[StudentQrReader] total students in subject ${widget.subjectId}: "
        "${subjectStudents.length}",
      );
      if (subjectStudents.isNotEmpty) {
        debugPrint(
          "[StudentQrReader] existing student IDs in subject: "
          "${subjectStudents.map((s) => "'${s.studentId}'").join(', ')}",
        );
      }

      final existingStudent = await AppDatabase.instance
          .getStudentByStudentIdInSubject(
            trimmedStudentId,
            int.parse(widget.subjectId),
          );

      if (existingStudent != null) {
        debugPrint(
          "[StudentQrReader] duplicate student ID detected in subject "
          "(searched: '$trimmedStudentId', found: '${existingStudent.studentId}', "
          "dbId: ${existingStudent.id}, firstName: ${existingStudent.firstName}, "
          "lastName: ${existingStudent.lastName})",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Student with this ID already exists in this subject!",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      debugPrint(
        "[StudentQrReader] no duplicate found in subject, proceeding with insert",
      );

      final student = StudentsCompanion(
        firstName: drift.Value(trimmedFirstName),
        lastName: drift.Value(trimmedLastName),
        studentId: drift.Value(trimmedStudentId),
        synced: drift.Value(false),
      );

      final insertedStudentID = await AppDatabase.instance.insertStudent(
        student,
      );
      await AppDatabase.instance.enrollStudent(
        int.parse(widget.subjectId),
        insertedStudentID,
      );

      debugPrint(
        "[StudentQrReader] insert succeeded (studentId: $trimmedStudentId, "
        "dbId: $insertedStudentID)",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Student Saved Successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Call the callback if provided (e.g., to navigate back)
        if (widget.onStudentAdded != null) {
          widget.onStudentAdded!();
        }
      }
    } catch (e, stackTrace) {
      debugPrint("Error saving student: $e");
      debugPrint("Stack trace: $stackTrace");
      if (mounted) {
        String errorMessage = "Error saving student";
        if (e.toString().contains("UNIQUE constraint")) {
          errorMessage = "Student with this ID already exists!";
        } else if (e.toString().contains("NOT NULL constraint")) {
          errorMessage = "All fields are required!";
        } else {
          errorMessage = "Error saving student: ${e.toString()}";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
