import 'dart:math';

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
  List<Map<String, dynamic>> filteredStudents = [];
  Subject? subjectDetails;
  String? semesterInfo;
  bool isLoadingAttendance = true;
  int totalClasses = 0;
  int averageAttendancePercent = 0;
  Map<String, StudentAttendanceSummary> attendanceSummaries = {};

  @override
  void initState() {
    super.initState();
    getSubjectDetails();
    _loadStudentsAndAttendance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void getSubjectDetails() async {
    debugPrint("Subject ID from student page: ${widget.subjectId}");

    try {
      final subject = await AppDatabase.instance.getSubjectByID(
        int.parse(widget.subjectId),
      );

      if (subject.isNotEmpty) {
        final subjectData = subject.first;
        // Get term/semester information
        Term? term;
        String? termLabel;
        try {
          term = await AppDatabase.instance.getTermById(subjectData.termId);
          if (term != null) {
            termLabel = '${term.term} ${term.startYear}-${term.endYear}';
          }
        } catch (e) {
          debugPrint("Error getting term details: $e");
        }

        setState(() {
          subjectDetails = subjectData;
          semesterInfo = termLabel;
        });
        debugPrint("Subject found: ${subjectDetails?.subjectName}");
      } else {
        debugPrint("No subject found with ID: ${widget.subjectId}");
        setState(() {
          subjectDetails = null;
          semesterInfo = null;
        });
      }
    } catch (e) {
      debugPrint("Error getting subject details: $e");
      setState(() {
        subjectDetails = null;
        semesterInfo = null;
      });
    }
  }

  Future<void> _loadStudentsAndAttendance() async {
    final subjectId = int.tryParse(widget.subjectId);
    if (subjectId == null) {
      if (mounted) {
        setState(() {
          isLoadingAttendance = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        isLoadingAttendance = true;
      });
    }

    try {
      final studentsData = await AppDatabase.instance.getStudentsInSubject(
        subjectId,
      );
      final sessionsData = await AppDatabase.instance.getSessionsBySubjectId(
        subjectId,
      );
      final sessionIds = sessionsData.map((session) => session.id).toList();
      final attendanceRecords = sessionIds.isEmpty
          ? <AttendanceData>[]
          : await AppDatabase.instance.getAttendanceBySessionIds(sessionIds);

      final summaryMap = <String, StudentAttendanceSummary>{};
      var totalAttendedRecords = 0;

      for (final student in studentsData) {
        final records = attendanceRecords
            .where((record) => record.studentId == student.studentId)
            .toList();

        final presentCount = records
            .where((record) => _matchesStatus(record.status, 'present'))
            .length;
        final lateCount = records
            .where((record) => _matchesStatus(record.status, 'late'))
            .length;
        final absentCount = records
            .where((record) => _matchesStatus(record.status, 'absent'))
            .length;

        totalAttendedRecords += presentCount + lateCount;

        final summary = StudentAttendanceSummary.fromCounts(
          present: presentCount,
          absent: absentCount,
          late: lateCount,
          totalClasses: sessionsData.length,
        );
        summaryMap[student.studentId] = summary;
      }

      final totalPossibleRecords = studentsData.length * sessionsData.length;
      final calculatedAverage = totalPossibleRecords == 0
          ? 0
          : min(
              100,
              ((totalAttendedRecords / totalPossibleRecords) * 100).round(),
            );

      if (!mounted) return;

      setState(() {
        students = studentsData.map((student) => student.toJson()).toList();
        filteredStudents = students;
        totalClasses = sessionsData.length;
        averageAttendancePercent = calculatedAverage;
        attendanceSummaries = summaryMap;
      });
    } catch (error) {
      debugPrint('Error loading student attendance stats: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingAttendance = false;
        });
      }
    }
  }

  bool _matchesStatus(String? status, String target) {
    if (status == null) return false;
    return status.toLowerCase().trim() == target;
  }

  Future<void> refreshData() async {
    await _loadStudentsAndAttendance();
    // Reset search and filter to show all students
    setState(() {
      searchQuery = '';
      selectedFilter = 'All';
    });
    filterStudents('');
  }

  void filterStudents(String query) {
    setState(() {
      // First, filter by search query
      List<Map<String, dynamic>> searchFiltered = students;
      if (query.isNotEmpty) {
        searchFiltered = students.where((student) {
          final fullName = '${student['firstName']} ${student['lastName']}'
              .toLowerCase();
          final studentId = student['studentId'].toString().toLowerCase();
          final searchLower = query.toLowerCase();

          return fullName.contains(searchLower) ||
              studentId.contains(searchLower);
        }).toList();
      }

      // Then, filter by attendance percentage based on selectedFilter
      if (selectedFilter == 'All') {
        filteredStudents = searchFiltered;
      } else {
        filteredStudents = searchFiltered.where((student) {
          final studentId = student['studentId']?.toString() ?? '';
          final stats =
              attendanceSummaries[studentId] ??
              StudentAttendanceSummary.fromCounts(
                present: 0,
                absent: 0,
                late: 0,
                totalClasses: totalClasses,
              );

          if (selectedFilter == 'Good (90%+)') {
            return stats.attendancePercentage >= 90;
          } else if (selectedFilter == 'At Risk (<75%)') {
            return stats.attendancePercentage < 75;
          }
          return true;
        }).toList();
      }
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddStudentPage(subjectId: widget.subjectId),
            ),
          );

          // Refresh data if a student was added
          if (result == true) {
            await refreshData();

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student list refreshed'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
        child: const Icon(Icons.add),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          RefreshIndicator(
            onRefresh: refreshData,
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (semesterInfo != null)
                          Text(
                            semesterInfo!,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
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
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                value: students.length.toString(),
                                label: 'Total Students',
                              ),
                            ),
                            Expanded(
                              child: _StatColumn(
                                value: '$averageAttendancePercent%',
                                label: 'Avg Attendance',
                              ),
                            ),
                            Expanded(
                              child: _StatColumn(
                                value: totalClasses.toString(),
                                label: 'Total Classes',
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
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                top: 12,
                                bottom: 12,
                              ),
                              child: Text(
                                'Student Attendance',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
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
                              filterStudents(value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search students...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: scheme.onSurfaceVariant,
                              ),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          searchQuery = '';
                                        });
                                        filterStudents('');
                                      },
                                    )
                                  : null,
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
                              onTap: () {
                                setState(() => selectedFilter = 'All');
                                filterStudents(searchQuery);
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterButton(
                              label: 'Good (90%+)',
                              isSelected: selectedFilter == 'Good (90%+)',
                              onTap: () {
                                setState(() => selectedFilter = 'Good (90%+)');
                                filterStudents(searchQuery);
                              },
                            ),
                            const SizedBox(width: 8),
                            _FilterButton(
                              label: 'At Risk (<75%)',
                              isSelected: selectedFilter == 'At Risk (<75%)',
                              onTap: () {
                                setState(
                                  () => selectedFilter = 'At Risk (<75%)',
                                );
                                filterStudents(searchQuery);
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Search Results Info
                  if (searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${filteredStudents.length} student${filteredStudents.length == 1 ? '' : 's'} found',
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // No Students Message
                  if (filteredStudents.isEmpty)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
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
                          Icon(
                            searchQuery.isNotEmpty
                                ? Icons.search_off
                                : Icons.people_outline,
                            size: 48,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'No students found'
                                : 'No students enrolled',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'Try searching with a different term'
                                : 'Add students to get started with attendance tracking',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Student List
                  ...filteredStudents.map((student) {
                    final studentId = student['studentId']?.toString() ?? '';
                    final stats =
                        attendanceSummaries[studentId] ??
                        StudentAttendanceSummary.fromCounts(
                          present: 0,
                          absent: 0,
                          late: 0,
                          totalClasses: totalClasses,
                        );

                    return _StudentCard(
                      student: StudentData(
                        name: '${student['firstName']} ${student['lastName']}',
                        firstName: student['firstName']?.toString() ?? '',
                        lastName: student['lastName']?.toString() ?? '',
                        id: student['studentId'],
                        present: stats.present,
                        absent: stats.absent,
                        late: stats.late,
                        attendancePercentage: stats.attendancePercentage,
                        status: stats.status,
                        statusColor: stats.statusColor,
                        databaseId: student['id'],
                      ),
                      onStudentUpdate: (updatedStudent) {
                        debugPrint('🔄 [STUDENT UPDATE] Student data updated:');
                        debugPrint(
                          '   📝 Old Data: name=${student['firstName']} ${student['lastName']}, id=${student['studentId']}',
                        );
                        debugPrint(
                          '   📝 New Data: name=${updatedStudent.name}, id=${updatedStudent.id}',
                        );
                        debugPrint(
                          '   🆔 Database ID: ${updatedStudent.databaseId}',
                        );
                        debugPrint(
                          '   ⏰ Update timestamp: ${DateTime.now().toIso8601String()}',
                        );

                        setState(() {
                          // Find the original index in the main students list
                          final originalIndex = students.indexWhere(
                            (s) => s['id'] == student['id'],
                          );
                          if (originalIndex != -1) {
                            students[originalIndex] = {
                              'id': updatedStudent.databaseId!,
                              'firstName': updatedStudent.firstName,
                              'lastName': updatedStudent.lastName,
                              'studentId': updatedStudent.id,
                            };
                            // Refresh the filtered list
                            filterStudents(searchQuery);
                            debugPrint(
                              '✅ [STUDENT UPDATE] UI updated successfully',
                            );
                          }
                        });
                      },
                      onStudentDelete: (studentId) {
                        setState(() {
                          // Find and remove from main students list
                          students.removeWhere((s) => s['id'] == studentId);
                          // Refresh the filtered list
                          filterStudents(searchQuery);
                        });
                      },
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (isLoadingAttendance)
            Positioned.fill(
              child: Container(
                color: scheme.background.withOpacity(0.85),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: scheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Tallying student attendances',
                      style: TextStyle(
                        color: scheme.onBackground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
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

class StudentAttendanceSummary {
  final int present;
  final int absent;
  final int late;
  final int attendancePercentage;
  final String status;
  final Color statusColor;

  const StudentAttendanceSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.attendancePercentage,
    required this.status,
    required this.statusColor,
  });

  factory StudentAttendanceSummary.fromCounts({
    required int present,
    required int absent,
    required int late,
    required int totalClasses,
  }) {
    if (totalClasses == 0) {
      return const StudentAttendanceSummary(
        present: 0,
        absent: 0,
        late: 0,
        attendancePercentage: 0,
        status: 'No Classes',
        statusColor: Colors.grey,
      );
    }

    final totalRecords = present + absent + late;
    if (totalRecords == 0) {
      return const StudentAttendanceSummary(
        present: 0,
        absent: 0,
        late: 0,
        attendancePercentage: 0,
        status: 'No Records',
        statusColor: Colors.grey,
      );
    }

    final attended = min(present + late, totalClasses);
    final attendancePercentage = min(
      100,
      ((attended / totalClasses) * 100).round(),
    );

    final statusLabel = attendancePercentage >= 90
        ? 'Excellent'
        : attendancePercentage >= 75
        ? 'On Track'
        : attendancePercentage >= 50
        ? 'Needs Work'
        : 'At Risk';
    final statusColor = attendancePercentage >= 90
        ? Colors.green
        : attendancePercentage >= 75
        ? Colors.orange
        : attendancePercentage >= 50
        ? Colors.amber
        : Colors.red;

    return StudentAttendanceSummary(
      present: present,
      absent: absent,
      late: late,
      attendancePercentage: attendancePercentage,
      status: statusLabel,
      statusColor: statusColor,
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentData student;
  final Function(StudentData) onStudentUpdate;
  final Function(int) onStudentDelete;

  const _StudentCard({
    required this.student,
    required this.onStudentUpdate,
    required this.onStudentDelete,
  });

  void _handleMenuAction(BuildContext context, String action) {
    debugPrint(
      '🎯 [STUDENT INTERACTION] Student tapped: ${student.name} (ID: ${student.id})',
    );
    debugPrint(
      '   📊 Student Data: name=${student.name}, id=${student.id}, databaseId=${student.databaseId}',
    );
    debugPrint(
      '   📈 Attendance Stats: present=${student.present}, absent=${student.absent}, late=${student.late}',
    );
    debugPrint('   ⚡ Action: $action');

    if (action == 'edit') {
      debugPrint(
        '✏️ [STUDENT EDIT] Opening edit dialog for student: ${student.name}',
      );
      _editStudent(context);
    } else if (action == 'delete') {
      debugPrint(
        '🗑️ [STUDENT DELETE] Opening delete confirmation for student: ${student.name}',
      );
      _deleteStudent(context);
    }
  }

  void _editStudent(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) =>
          StudentEditPopup(student: student, onUpdate: onStudentUpdate),
    );
  }

  void _deleteStudent(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student?'),
        content: const Text('This will remove the student from this subject.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && student.databaseId != null) {
      try {
        // Delete the student and all related data (enrollments, attendance)
        await AppDatabase.instance.deleteStudentWithRelations(
          student.databaseId!,
        );
        onStudentDelete(student.databaseId!);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting student: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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

              // Name and Menu Row (flexes to top)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: scheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onSelected: (value) => _handleMenuAction(context, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Student'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete Student',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Details Container
          Row(
            children: [
              const SizedBox(width: 12), // Align with avatar
              // Left side: Student ID and Attendance details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${student.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.present} Present, ${student.absent} Absent, ${student.late} Late',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
        ],
      ),
    );
  }
}

class StudentData {
  /// Full display name (first + last), mainly for UI.
  final String name;

  /// Separate first name and last name, so we don't have to guess
  /// when editing and saving back to the database.
  final String firstName;
  final String lastName;

  final String id;
  final int present;
  final int absent;
  final int late;
  final int attendancePercentage;
  final String status;
  final Color statusColor;
  final int? databaseId; // Add database ID for updates

  StudentData({
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.id,
    required this.present,
    required this.absent,
    required this.late,
    required this.attendancePercentage,
    required this.status,
    required this.statusColor,
    this.databaseId,
  });
}

class StudentEditPopup extends StatefulWidget {
  final StudentData student;
  final Function(StudentData) onUpdate;

  const StudentEditPopup({
    super.key,
    required this.student,
    required this.onUpdate,
  });

  @override
  State<StudentEditPopup> createState() => _StudentEditPopupState();
}

class _StudentEditPopupState extends State<StudentEditPopup> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _studentIdController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.student.firstName,
    );
    _lastNameController = TextEditingController(text: widget.student.lastName);
    _studentIdController = TextEditingController(text: widget.student.id);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Student',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _studentIdController,
                    decoration: InputDecoration(
                      labelText: 'Student ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter student ID';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveStudent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (widget.student.databaseId != null) {
          await AppDatabase.instance.updateStudent(
            widget.student.databaseId!,
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
            _studentIdController.text.trim(),
          );
        }

        // Update the student data
        final updatedStudent = StudentData(
          name:
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          id: _studentIdController.text.trim(),
          present: widget.student.present,
          absent: widget.student.absent,
          late: widget.student.late,
          attendancePercentage: widget.student.attendancePercentage,
          status: widget.student.status,
          statusColor: widget.student.statusColor,
          databaseId: widget.student.databaseId,
        );

        widget.onUpdate(updatedStudent);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating student: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
