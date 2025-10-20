import 'package:flutter/material.dart';
import 'class_card.dart';
import 'empty_classes_state.dart';

class ClassList extends StatelessWidget {
  final List<Map<String, dynamic>> finalData;
  final VoidCallback reloadStates;
  final String? searchQuery;
  final int? selectedTermId;
  const ClassList({
    super.key,
    required this.finalData,
    required this.reloadStates,
    this.searchQuery,
    this.selectedTermId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const SizedBox(height: 12), ..._buildClassList(context)],
    );
  }

  List<Widget> _buildClassList(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> classesBySubject = {};
    debugPrint("Schedule Data: ${finalData.toString()}");

    for (final data in finalData) {
      // If a term filter is selected, skip items that don't match
      final itemTermId = data['termData']?['id'];
      if (selectedTermId != null) {
        if (itemTermId == null) continue;
        if (itemTermId != selectedTermId) continue;
      }
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

    // Group entries by semester header string
    final Map<String, List<Map<String, dynamic>>> bySemester = {};
    for (final entry in classesBySubject.entries) {
      for (final item in entry.value) {
        final term = item['termData']?['term']?.toString() ?? 'Unknown';
        final startYear = item['termData']?['startYear']?.toString() ?? '';
        final endYear = item['termData']?['endYear']?.toString() ?? '';
        final header = (startYear.isNotEmpty && endYear.isNotEmpty)
            ? '$term $startYear-$endYear'
            : term;
        if (!bySemester.containsKey(header)) bySemester[header] = [];
        // add the single item to the semester group
        bySemester[header]!.add(item);
      }
    }

    final widgets = <Widget>[];
    var cardCount = 0;

    // iterate headers in insertion order
    for (final header in bySemester.keys) {
      final items = bySemester[header]!;

      // build unique subject list within this semester (apply search filter first)
      final Map<String, List<Map<String, dynamic>>> subjectsMap = {};
      for (final data in items) {
        final subject = data['subjectData']?['subjectName']?.toString() ?? '';
        if (searchQuery != null && searchQuery!.isNotEmpty) {
          if (!subject.toLowerCase().contains(searchQuery!.toLowerCase()))
            continue;
        }
        final classID = data['id']?.toString() ?? '';
        if (subject.isNotEmpty) {
          if (!subjectsMap.containsKey(subject)) subjectsMap[subject] = [];
          subjectsMap[subject]!.add({'id': classID, ...data});
        }
      }

      if (subjectsMap.isEmpty)
        continue; // skip this header if nothing matches search

      // add header (only after we know there are subjects to show)
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
          child: Text(
            header,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      );

      for (final entry in subjectsMap.entries) {
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

        widgets.add(
          ClassCard(
            subject: subject,
            classID: classSessions.first['id']?.toString() ?? '',
            courseCode: courseCode,
            sessions: sessions,
            room: room,
            startTime: startTime,
            endTime: endTime,
            status: 'SCHEDULED',
            semester: "$term $startYear - $endYear",
            yearLevel:
                firstSession['subjectData']['yearLevel']?.toString() ?? '',
            section: firstSession['subjectData']['section']?.toString() ?? '',
            profId: firstSession['subjectData']['profId']?.toString() ?? '',
            subjectId: firstSession['subjectData']['id'] ?? 0,
            reloadStates: reloadStates,
            subjectData: firstSession['subjectData'],
            scheduleData: sessions.toList(),
          ),
        );
        cardCount += 1;
      }
    }

    if (cardCount == 0) {
      return [const EmptyClassesState()];
    }

    return widgets;
  }
}
