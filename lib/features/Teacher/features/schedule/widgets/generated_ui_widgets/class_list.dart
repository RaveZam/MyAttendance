import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'class_card.dart';
import 'empty_classes_state.dart';

class ClassList extends StatelessWidget {
  final List<Map<String, dynamic>> finalData;

  const ClassList({super.key, required this.finalData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Classes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ..._buildClassList(),
      ],
    );
  }

  List<Widget> _buildClassList() {
    final Map<String, List<Map<String, dynamic>>> classesBySubject = {};
    debugPrint("Schedule Data: ${finalData.toString()}");

    for (final data in finalData) {
      debugPrint("Data ${data['termId']}");
      final subject = data['subjectData']['subjectName'] ?? '';
      final classID = data['id']?.toString() ?? '';
      if (subject.isNotEmpty) {
        if (!classesBySubject.containsKey(subject)) {
          classesBySubject[subject] = [];
        }
        classesBySubject[subject]!.add({'id': classID, ...data});
      }
    }

    if (classesBySubject.isEmpty) {
      return [const EmptyClassesState()];
    }

    return classesBySubject.entries.map((entry) {
      final subject = entry.key;
      final classSessions = entry.value;
      // debugPrint("Class Sessions ${classSessions.toString()}");

      final sessions = classSessions.map<Map<String, dynamic>>((s) {
        return {
          "day": s['day'],
          "startTime": s['startTime'],
          "endTime": s['endTime'],
          "room": s['room'],
        };
      });

      final firstSession = classSessions.first;
      debugPrint("first session: ${firstSession.toString()}");
      final startTime = firstSession['startTime'].toString();
      final endTime = firstSession['endTime'].toString();
      final courseCode =
          firstSession['subjectData']['subjectCode']?.toString() ?? "0";

      final room = firstSession['room']?.toString() ?? 'TBA';
      final term = firstSession['termData']['term']?.toString() ?? "0";
      final startYear =
          firstSession['termData']['startYear']?.toString() ?? "0";
      final endYear = firstSession['termData']['endYear']?.toString() ?? "0";

      return ClassCard(
        subject: subject,
        classID: classSessions.first['id']?.toString() ?? '',
        courseCode: courseCode,
        sessions: sessions,
        room: room,
        startTime: startTime,
        endTime: endTime,
        status: 'SCHEDULED',
        semester: "$term $startYear - $endYear",
      );
    }).toList();
  }
}
