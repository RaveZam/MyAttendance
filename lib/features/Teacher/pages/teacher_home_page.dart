import 'package:flutter/material.dart';
import 'package:myattendance/core/widgets/custom_app_bar.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/display_current_class.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/display_next_class.dart';
import 'package:myattendance/features/Teacher/widgets/overview_section.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  @override
  void initState() {
    DisplayCurrentClass();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Home', icon: Icons.home_rounded),
      backgroundColor: Colors.grey[50],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                OverviewSection(),
                DisplayCurrentClass(),
                DisplayNextClass(),
                // QR Code Section
                // Container(
                //   padding: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(16),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withValues(alpha: 0.08),
                //         blurRadius: 10,
                //         offset: const Offset(0, 4),
                //       ),
                //     ],
                //   ),
                //   child: const Qrcode(),
                // ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Students can scan this QR code to mark their attendance",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
