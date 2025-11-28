import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:myattendance/features/QRFeature/widgets/student_qr_reader.dart';

class AddStudentPage extends StatefulWidget {
  final String subjectId;
  const AddStudentPage({super.key, required this.subjectId});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final GlobalKey<StudentQrReaderState> _qrReaderKey =
      GlobalKey<StudentQrReaderState>();
  int _selectedTab = 0; // 0 for Manual, 1 for QR

  Future<void> addStudent({
    required String firstName,
    required String lastName,
    required String studentId,
  }) async {
    try {
      // Trim and validate inputs
      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();
      final trimmedStudentId = studentId.trim();

      // Validate that all fields are not empty
      if (trimmedFirstName.isEmpty ||
          trimmedLastName.isEmpty ||
          trimmedStudentId.isEmpty) {
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

      // Check if student already exists
      final allStudents = await AppDatabase.instance.getAllStudents();
      final existingStudent = allStudents.any(
        (student) =>
            student.studentId.trim().toLowerCase() ==
            trimmedStudentId.toLowerCase(),
      );

      if (existingStudent) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Student with this ID already exists!"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Student Saved Successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back with success result
        Navigator.pop(context, true);
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

  Future<void> addStudentFromForm() async {
    if (_formKey.currentState!.saveAndValidate()) {
      await addStudent(
        firstName: _formKey.currentState!.value['firstName'],
        lastName: _formKey.currentState!.value['lastName'],
        studentId: _formKey.currentState!.value['studentID'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Student"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab selector
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0
                              ? Colors.black
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: _selectedTab == 0
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Manual Entry',
                              style: TextStyle(
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: _selectedTab == 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1
                              ? Colors.black
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: _selectedTab == 1
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Via QR',
                              style: TextStyle(
                                color: _selectedTab == 1
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: _selectedTab == 1
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content based on selected tab
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _selectedTab == 0
                    ? _buildManualEntryForm()
                    : _buildQRScanner(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryForm() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(
            name: 'firstName',
            decoration: const InputDecoration(
              labelText: 'First Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'lastName',
            decoration: const InputDecoration(
              labelText: 'Last Name',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'studentID',
            decoration: const InputDecoration(
              labelText: 'Student ID',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            validator: FormBuilderValidators.required(),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              onPressed: addStudentFromForm,
              label: const Text("Save Student", style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanner() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
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
              const Text(
                'Scan Student QR Code',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Center(
                child: StudentQrReader(
                  key: _qrReaderKey,
                  subjectId: widget.subjectId,
                  onStudentAdded: () {
                    // Navigate back with success result
                    Navigator.pop(context, true);
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Position the QR code within the frame to scan',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'QR Code Format',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'The QR code should contain JSON with the following fields:',
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                '• first_name\n• last_name\n• student_id',
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
