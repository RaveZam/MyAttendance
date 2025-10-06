import 'package:flutter/material.dart';
import 'class_card.dart';
import 'empty_classes_state.dart';

class ClassList extends StatelessWidget {
  final List<Map<String, dynamic>> finalData;
  final VoidCallback reloadStates;
  const ClassList({
    super.key,
    required this.finalData,
    required this.reloadStates,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const SizedBox(height: 12), ..._buildClassList()],
    );
  }

  List<Widget> _buildClassList() {
    final Map<String, List<Map<String, dynamic>>> classesBySubject = {};
    debugPrint("Schedule Data: ${finalData.toString()}");

    for (final data in finalData) {
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
      final uniqueSessions = <String, Map<String, dynamic>>{};
      for (final s in classSessions) {
        final key =
            "${s['day']}_${s['startTime']}_${s['endTime']}_${s['room']}";
        if (!uniqueSessions.containsKey(key)) {
          uniqueSessions[key] = {
            "day": s['day'],
            "startTime": s['startTime'],
            "endTime": s['endTime'],
            "room": s['room'],
          };
        }
      }
      final sessions = uniqueSessions.values.toList();

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
        yearLevel: firstSession['subjectData']['yearLevel']?.toString() ?? '',
        section: firstSession['subjectData']['section']?.toString() ?? '',
        profId: firstSession['subjectData']['profId']?.toString() ?? '',
        subjectId: firstSession['subjectData']['id'] ?? 0,
        reloadStates: reloadStates,
        subjectData: firstSession['subjectData'],
        scheduleData: sessions.toList(),
      );
    }).toList();
  }
}
