import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentQr extends StatefulWidget {
  const StudentQr({super.key});

  @override
  State<StudentQr> createState() => _StudentQrState();
}

class _StudentQrState extends State<StudentQr> {
  User? get _currentUser => Supabase.instance.client.auth.currentUser;
  Map<String, dynamic> studentData = {};

  @override
  void initState() {
    getStudentData();
    debugPrint('StudentQr: $_currentUser');
    super.initState();
  }

  void getStudentData() {
    setState(() {
      studentData = {
        "first_name": _currentUser?.userMetadata?['first_name'],
        "last_name": _currentUser?.userMetadata?['last_name'],
        "student_id": _currentUser?.userMetadata?['student_id'],
        "uuid": _currentUser?.id,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final studentJsonString = jsonEncode(studentData);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${(studentData["first_name"] ?? '').toString()} ${(studentData["last_name"] ?? '').toString()}'
                                      .trim()
                                      .isEmpty
                                  ? 'Your QR'
                                  : '${(studentData["first_name"] ?? '').toString()} ${(studentData["last_name"] ?? '').toString()}'
                                        .trim(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            Text(
                              'ID: ${(studentData["student_id"] ?? '-').toString()}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // QR Code
                PrettyQrView.data(
                  data: studentJsonString,
                  decoration: const PrettyQrDecoration(
                    quietZone: PrettyQrQuietZone.standart,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
