import 'package:flutter/material.dart';
import 'class_card.dart';
import 'empty_classes_state.dart';

class ClassList extends StatelessWidget {
  final List<Map<String, dynamic>> scheduleData;

  const ClassList({super.key, required this.scheduleData});

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
    // Group schedule data by subject to create class entries
    final Map<String, List<Map<String, dynamic>>> classesBySubject = {};

    for (final schedule in scheduleData) {
      final subject = schedule['subject']?.toString() ?? '';
      final classID = schedule['id']?.toString() ?? '';
      if (subject.isNotEmpty) {
        if (!classesBySubject.containsKey(subject)) {
          classesBySubject[subject] = [];
        }
        classesBySubject[subject]!.add({'id': classID, ...schedule});
      }
    }

    // If no schedule data, show empty state
    if (classesBySubject.isEmpty) {
      return [const EmptyClassesState()];
    }

    // Generate class list from actual data
    return classesBySubject.entries.map((entry) {
      final subject = entry.key;
      final classSessions = entry.value;

      // Extract course details from the first session
      final firstSession = classSessions.first;
      final courseCode =
          firstSession['course_code']?.toString() ??
          firstSession['code']?.toString() ??
          subject.split(' ').last; // Use last word as fallback
      final location =
          firstSession['location']?.toString() ??
          firstSession['room']?.toString() ??
          'TBA';
      final time = firstSession['time']?.toString() ?? 'TBA';
      final instructor =
          firstSession['instructor']?.toString() ??
          firstSession['teacher']?.toString() ??
          'TBA';

      return ClassCard(
        subject: subject,
        classID: classSessions.first['id']?.toString() ?? '',
        courseCode: courseCode,
        location: location,
        time: time,
        instructor: instructor,
        status: 'SCHEDULED',
        semester: 'SPRING 2025',
      );
    }).toList();
  }
}
