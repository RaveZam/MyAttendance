import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/import_schedule.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/generated_ui_widgets/statistics_card.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/generated_ui_widgets/schedule_grid.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/generated_ui_widgets/class_list.dart';
import 'package:myattendance/features/Teacher/features/schedule/helpers/format_time.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> _scheduleData = [];
  final ImportSchedule _importSchedule = ImportSchedule();
  final db = AppDatabase();
  @override
  void initState() {
    super.initState();
    loadSchedule();
  }

  void loadSchedule() async {
    final schedules = await db.getAllSchedules();

    if (schedules.isNotEmpty) {
      setState(() {
        _scheduleData = schedules.map((e) => e.toJson()).toList();
      });
    }
  }

  void handleImportSchedule() async {
    final data = await _importSchedule.importSchedule();
    if (data != null) {
      setState(() {
        _scheduleData = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _scheduleData.isEmpty
          ? _buildEmptyState()
          : _buildSchedule(_scheduleData, context),
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
                    'Import your schedule from a CSV file to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: handleImportSchedule,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import CSV'),
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
  // Process your actual scheduleData into weekly format
  final weeklySchedule = _processScheduleData(scheduleData);

  return SingleChildScrollView(
    child: Column(
      children: [
        // Statistics at the top
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

        const SizedBox(height: 16),

        // Schedule Grid
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
          child: ScheduleGrid(weeklySchedule: weeklySchedule),
        ),

        const SizedBox(height: 16),

        // Class List
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClassList(scheduleData: scheduleData),
        ),
      ],
    ),
  );
}

// Process your actual scheduleData into weekly format
Map<String, Map<String, String>> _processScheduleData(
  List<Map<String, dynamic>> scheduleData,
) {
  final weeklySchedule = <String, Map<String, String>>{
    'monday': {},
    'tuesday': {},
    'wednesday': {},
    'thursday': {},
    'friday': {},
  };

  for (final schedule in scheduleData) {
    // Extract day, time, and subject from your data
    final day = (schedule['day'] ?? '').toString().toLowerCase();
    final time = schedule['time'] ?? '';
    final subject = schedule['subject'] ?? '';

    // Map day names to our format
    String dayKey = '';
    switch (day) {
      case 'monday':
      case 'mon':
        dayKey = 'monday';
        break;
      case 'tuesday':
      case 'tue':
        dayKey = 'tuesday';
        break;
      case 'wednesday':
      case 'wed':
        dayKey = 'wednesday';
        break;
      case 'thursday':
      case 'thu':
        dayKey = 'thursday';
        break;
      case 'friday':
      case 'fri':
        dayKey = 'friday';
        break;
    }

    if (dayKey.isNotEmpty && time.isNotEmpty && subject.isNotEmpty) {
      final formattedTime = FormatTime().formatTime(time);
      if (formattedTime.isNotEmpty) {
        weeklySchedule[dayKey]![formattedTime] = subject;
      }
    }
  }

  return weeklySchedule;
}
