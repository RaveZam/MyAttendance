import 'package:flutter/material.dart';
import 'student_add_page.dart';

import 'package:myattendance/core/database/app_database.dart';

class StudentPage extends StatefulWidget {
  final String subjectId;
  const StudentPage({super.key, required this.subjectId});
  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  List<Map<String, dynamic>> students = [];
  Subject? subjectDetails;

  @override
  void initState() {
    super.initState();
    getSubjectDetails();
    getAllStudents();
  }

  void getSubjectDetails() async {
    debugPrint("Subject ID from student page: ${widget.subjectId}");

    try {
      final subject = await AppDatabase.instance.getSubjectByID(
        int.parse(widget.subjectId),
      );

      if (subject.isNotEmpty) {
        setState(() {
          subjectDetails = subject.first;
        });
        debugPrint("Subject found: ${subjectDetails?.subjectName}");
      } else {
        debugPrint("No subject found with ID: ${widget.subjectId}");
        setState(() {
          subjectDetails = null;
        });
      }
    } catch (e) {
      debugPrint("Error getting subject details: $e");
      setState(() {
        subjectDetails = null;
      });
    }
  }

  void getAllStudents() async {
    final studentsData = await AppDatabase.instance.getStudentsInSubject(
      int.parse(widget.subjectId),
    );

    setState(() {
      students = studentsData.map((student) => student.toJson()).toList();
    });
  }

  String selectedFilter = 'All';
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Students List',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: scheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddStudentPage(subjectId: widget.subjectId),
            ),
          );
        },
        child: const Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (students.isEmpty)
              EmptyStudentsScreen(
                onAddStudent: () {},
                onJoinViaBLE: () {},
                subjectId: widget.subjectId,
              ),
            if (students.isNotEmpty) ...[
              // Class Overview Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${subjectDetails?.subjectName} ${subjectDetails?.subjectCode}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${subjectDetails?.yearLevel} ${subjectDetails?.section}',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatColumn(
                            value: '124',
                            label: 'Total Students',
                          ),
                        ),
                        Expanded(
                          child: _StatColumn(
                            value: '87%',
                            label: 'Avg Attendance',
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              _StatColumn(value: '32', label: 'Total Classes'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Student Attendance Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Student Attendance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: scheme.onSurfaceVariant,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),

                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: scheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    // Filter Buttons
                    Row(
                      children: [
                        _FilterButton(
                          label: 'All',
                          isSelected: selectedFilter == 'All',
                          onTap: () => setState(() => selectedFilter = 'All'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: 'Good (90%+)',
                          isSelected: selectedFilter == 'Good (90%+)',
                          onTap: () =>
                              setState(() => selectedFilter = 'Good (90%+)'),
                        ),
                        const SizedBox(width: 8),
                        _FilterButton(
                          label: 'At Risk (<75%)',
                          isSelected: selectedFilter == 'At Risk (<75%)',
                          onTap: () =>
                              setState(() => selectedFilter = 'At Risk (<75%)'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Student List
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return _StudentCard(
                    student: StudentData(
                      name: student['firstName'] + ' ' + student['lastName'],
                      id: student['studentId'],
                      present: 0,
                      absent: 0,
                      late: 0,
                      attendancePercentage: 0,
                      status: 'Good',
                      statusColor: Colors.green,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStudentsScreen extends StatelessWidget {
  final VoidCallback onAddStudent;
  final VoidCallback onJoinViaBLE;
  final String subjectId;
  const EmptyStudentsScreen({
    super.key,
    required this.onAddStudent,
    required this.onJoinViaBLE,
    required this.subjectId,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 72, color: scheme.primary),
            const SizedBox(height: 20),
            Text(
              'No Students Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "You can add students manually or let them join using the class code via BLE.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddStudentPage(subjectId: subjectId),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.person_add, size: 28),
                        SizedBox(height: 8),
                        Text("Add"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onJoinViaBLE,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.bluetooth, size: 28),
                        SizedBox(height: 8),
                        Text("Join"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentData student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.person,
                  color: scheme.onSurfaceVariant,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),

              // Student Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${student.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${student.present} Present, ${student.absent} Absent, ${student.late} Late',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Status
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: student.statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${student.attendancePercentage}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.status,
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress Bar
          LinearProgressIndicator(
            value: student.attendancePercentage / 100,
            backgroundColor: scheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              student.attendancePercentage >= 90
                  ? Colors.green.shade600
                  : student.attendancePercentage >= 75
                  ? Colors.orange.shade600
                  : Colors.red.shade600,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),

          // Action Required for At Risk students
          if (student.attendancePercentage < 75) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Action Required',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: scheme.surfaceVariant,
                    foregroundColor: scheme.onSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Contact', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class StudentData {
  final String name;
  final String id;
  final int present;
  final int absent;
  final int late;
  final int attendancePercentage;
  final String status;
  final Color statusColor;

  StudentData({
    required this.name,
    required this.id,
    required this.present,
    required this.absent,
    required this.late,
    required this.attendancePercentage,
    required this.status,
    required this.statusColor,
  });
}
