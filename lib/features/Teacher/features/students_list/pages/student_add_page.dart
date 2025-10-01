import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class AddStudentPage extends StatefulWidget {
  final String subjectId;
  const AddStudentPage({super.key, required this.subjectId});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormBuilderState>();

  void addStudent() async {
    debugPrint(_formKey.currentState!.value.toString());

    final student = StudentsCompanion(
      firstName: drift.Value(_formKey.currentState!.value['firstName']),
      lastName: drift.Value(_formKey.currentState!.value['lastName']),
      studentId: drift.Value(_formKey.currentState!.value['studentID']),
      synced: drift.Value(false),
    );

    final studentID = await AppDatabase.instance.insertStudent(student);
    AppDatabase.instance.enrollStudent(int.parse(widget.subjectId), studentID);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Student Saved Successfully!"),
        backgroundColor: Colors.green,
      ),
    );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormBuilder(
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
                        onPressed: () {
                          if (_formKey.currentState!.saveAndValidate()) {
                            addStudent();
                          }
                        },
                        label: const Text(
                          "Save Student",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
