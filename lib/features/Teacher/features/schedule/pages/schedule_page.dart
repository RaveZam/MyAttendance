import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/generated_ui_widgets/statistics_card.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/generated_ui_widgets/class_list.dart';
import 'package:myattendance/features/Teacher/features/schedule/pages/add_subject_page.dart';
import 'package:myattendance/core/widgets/custom_app_bar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> _scheduleData = [];
  List<Map<String, dynamic>> _subjectsData = [];
  final db = AppDatabase.instance;
  @override
  void initState() {
    super.initState();
    // loadSubjects();
    // loadSchedule();
    db.clearAllData();
  }

  void loadSubjects() async {
    final subjects = await db.getAllSubjects();
    setState(() {
      _subjectsData = subjects.map((e) => e.toJson()).toList();
    });
    debugPrint(_subjectsData.toString());
  }

  void loadSchedule() async {
    final schedules = await db.getAllSchedules();

    if (schedules.isNotEmpty) {
      setState(() {
        _scheduleData = schedules.map((e) => e.toJson()).toList();
      });
      debugPrint(_scheduleData.toString());
    }
  }

  void _navigateToAddSubject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSubjectPage()),
    );

    if (result == true) {
      loadSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Schedule',
        icon: Icons.calendar_month_rounded,
      ),
      backgroundColor: Colors.grey[50],
      body: _scheduleData.isEmpty
          ? _buildEmptyState()
          : _buildSchedule(_scheduleData, context),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddSubject,
        child: const Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Schedule Found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your first class to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _navigateToAddSubject,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Class'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildSchedule(
  List<Map<String, dynamic>> scheduleData,
  BuildContext context,
) {
  return SingleChildScrollView(
    child: Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatisticsCard(
                value: '5',
                label: 'Total Classes',
                color: Colors.blue,
              ),
              StatisticsCard(
                value: '3',
                label: 'Active Today',
                color: Colors.green,
              ),
              StatisticsCard(
                value: '412',
                label: 'Total Students',
                color: Colors.orange,
              ),
            ],
          ),
        ),

        // Class List
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClassList(scheduleData: scheduleData),
        ),
      ],
    ),
  );
}
