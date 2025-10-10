import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/generated_ui_widgets/class_list.dart';
import 'package:myattendance/features/Teacher/features/schedule/pages/add_subject_page.dart';
import 'package:myattendance/core/widgets/custom_app_bar.dart';

class SubjectPage extends StatefulWidget {
  const SubjectPage({super.key});

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  List<Map<String, dynamic>> _scheduleData = [];
  List<Map<String, dynamic>> _subjectsData = [];

  final db = AppDatabase.instance;
  @override
  void initState() {
    super.initState();
    loadSchedule();
    loadSubjects();
    db.ensureTermsExist(db);
  }

  final List<Map<String, dynamic>> _finalData = [];

  Future<Term?> getTermById(int id) async {
    return await db.getTermById(id);
  }

  Future<void> combineData() async {
    _finalData.clear();
    for (var schedule in _scheduleData) {
      var matchingSubject = _subjectsData.firstWhere(
        (subject) => subject['id'] == schedule['subjectId'],
        orElse: () => {},
      );
      if (matchingSubject.isEmpty) {
        // If a schedule exists without a matching subject (out of sync), skip
        continue;
      }

      final int subjectTermId =
          matchingSubject['termId'] ?? matchingSubject['term_id'] ?? 0;
      final term = subjectTermId != 0 ? await getTermById(subjectTermId) : null;

      if (term == null) {
        // No term yet; still include the item without termData to avoid dropping
      }
      final termData = {
        if (term != null) 'id': term.id,
        if (term != null) 'term': term.term,
        if (term != null) 'startYear': term.startYear,
        if (term != null) 'endYear': term.endYear,
        if (term != null) 'synced': term.synced,
      };

      var combined = {
        ...schedule,
        'subjectData': matchingSubject,
        "termData": termData,
      };
      combined.remove('subjectId');
      // termId removed from schedule since term is now on subject
      _finalData.add(combined);
    }
    setState(() {});
  }

  Future<void> loadSubjects() async {
    final subjects = await db.getAllSubjects();
    setState(() {
      _subjectsData = subjects.map((e) => e.toJson()).toList();
    });
    if (_subjectsData.isNotEmpty && _scheduleData.isNotEmpty) {
      await combineData();
    }
  }

  Future<void> loadSchedule() async {
    final schedules = await db.getAllSchedules();
    setState(() {
      _scheduleData = schedules.map((e) => e.toJson()).toList();
    });
    if (_scheduleData.isNotEmpty && _subjectsData.isNotEmpty) {
      await combineData();
    }
  }

  void _navigateToAddSubject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddSubjectPage()),
    );

    if (result == true) {
      await refreshData();
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _scheduleData.clear();
      _subjectsData.clear();
      _finalData.clear();
    });
    await loadSchedule();
    await loadSubjects();
    await combineData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Subjects',
        icon: Icons.calendar_month_rounded,
      ),
      backgroundColor: Colors.grey[50],
      body: _scheduleData.isEmpty
          ? _buildEmptyState()
          : _buildSchedule(_finalData, context, refreshData),
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
  List<Map<String, dynamic>> finalData,
  BuildContext context,
  VoidCallback refreshData,
) {
  return SingleChildScrollView(
    child: Column(
      children: [
        // Class List
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClassList(finalData: finalData, reloadStates: refreshData),
        ),
      ],
    ),
  );
}
