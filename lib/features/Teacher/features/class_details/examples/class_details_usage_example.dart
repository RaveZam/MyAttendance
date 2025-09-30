import 'package:flutter/material.dart';
import 'package:myattendance/features/Teacher/features/class_details/pages/class_details_page.dart';

/// Example usage of the enhanced Class Details page
/// This demonstrates how to navigate to the Class Details page with full class information
class ClassDetailsUsageExample extends StatelessWidget {
  const ClassDetailsUsageExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Details Example')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _navigateToClassDetails(context),
          child: const Text('View Class Details'),
        ),
      ),
    );
  }

  void _navigateToClassDetails(BuildContext context) {
    // Example with multiple sessions
    final sessions = [
      {
        'startTime': '09:00',
        'endTime': '10:30',
        'room': 'Room 301',
        'day': 'Monday',
      },
      {
        'startTime': '14:00',
        'endTime': '15:30',
        'room': 'Lab 205',
        'day': 'Wednesday',
      },
      {
        'startTime': '09:00',
        'endTime': '10:30',
        'room': 'Room 301',
        'day': 'Friday',
      },
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassDetailsPage(
          subject: 'Data Structures and Algorithms',
          courseCode: 'CS-201',
          room: 'Room 301',
          startTime: '09:00 AM',
          endTime: '10:30 AM',
          status: 'Active',
          semester: '1st Semester',
          classID: 'CS-201-A',
          yearLevel: '2nd Year',
          section: 'Section A',
          profId: 'PROF001',
          sessions: sessions,
        ),
      ),
    );
  }
}

/// Example of how to use the Class Details page with data from database
class ClassDetailsWithDatabaseExample extends StatefulWidget {
  const ClassDetailsWithDatabaseExample({super.key});

  @override
  State<ClassDetailsWithDatabaseExample> createState() =>
      _ClassDetailsWithDatabaseExampleState();
}

class _ClassDetailsWithDatabaseExampleState
    extends State<ClassDetailsWithDatabaseExample> {
  bool _isLoading = true;
  Map<String, dynamic>? _classInfo;

  @override
  void initState() {
    super.initState();
    _loadClassInfo();
  }

  Future<void> _loadClassInfo() async {
    // This would typically be called with a real subject ID
    // For example: final classInfo = await AppDatabase.instance.getCompleteClassInfo(subjectId);

    // Simulated data for demonstration
    setState(() {
      _classInfo = {
        'subject': {
          'subjectName': 'Advanced Programming',
          'subjectCode': 'CS-301',
          'yearLevel': '3rd Year',
          'section': 'Section B',
          'profId': 'PROF002',
        },
        'schedule': {
          'day': 'Monday',
          'startTime': '02:00 PM',
          'endTime': '03:30 PM',
          'room': 'Lab 205',
        },
        'term': {
          'term': '2nd Semester',
          'startYear': '2024',
          'endYear': '2025',
        },
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_classInfo == null) {
      return const Scaffold(
        body: Center(child: Text('No class information available')),
      );
    }

    final subject = _classInfo!['subject'];
    final schedule = _classInfo!['schedule'];
    final term = _classInfo!['term'];

    // Example sessions data from database
    final sessions = [
      {
        'startTime': schedule['startTime'],
        'endTime': schedule['endTime'],
        'room': schedule['room'],
        'day': schedule['day'],
      },
      // Additional sessions could be fetched from database
      {
        'startTime': '11:00',
        'endTime': '12:30',
        'room': 'Lab 205',
        'day': 'Wednesday',
      },
    ];

    return ClassDetailsPage(
      subject: subject['subjectName'],
      courseCode: subject['subjectCode'],
      room: schedule['room'],
      startTime: schedule['startTime'],
      endTime: schedule['endTime'],
      status: 'Active',
      semester: term['term'],
      classID: '${subject['subjectCode']}-${subject['section']}',
      yearLevel: subject['yearLevel'],
      section: subject['section'],
      profId: subject['profId'],
      sessions: sessions,
    );
  }
}
