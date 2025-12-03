import 'package:flutter/material.dart';
import 'package:myattendance/core/widgets/custom_app_bar.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/display_current_class.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/display_next_class.dart';
import 'package:myattendance/features/Teacher/widgets/chart_comparison.dart';
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
                ChartComparison(),
                DisplayCurrentClass(),
                DisplayNextClass(),

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
