import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/core/logic/schedule_filter.dart';
import 'package:provider/provider.dart';

class DisplayCurrentClass extends StatelessWidget {
  DisplayCurrentClass({super.key});
  final schedules = AppDatabase().getAllSchedules();

  final ScheduleFilter currentClass = ScheduleFilter();

  Future<void> displaytCurrentClass() async {
    final schedules = await AppDatabase().getAllSchedules();
    debugPrint(
      'Current Class: ${currentClass.getCurrentClass(schedules).toString()}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(children: [Text('Test')]));
  }
}
