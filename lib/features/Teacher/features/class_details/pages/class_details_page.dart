import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/features/Teacher/features/students_list/pages/student_page.dart';
import 'package:myattendance/features/Teacher/features/class_details/widgets/class_details_info_card.dart';
import 'package:myattendance/features/Teacher/features/schedule/pages/add_subject_page.dart';
import 'package:myattendance/features/Teacher/features/attendance/pages/attendance_page.dart';
import 'package:myattendance/features/Teacher/features/session/pages/session_page.dart';
import 'package:drift/drift.dart' as drift;

class ClassDetailsPage extends StatefulWidget {
  final String subject;
  final String courseCode;
  final String room;
  final String startTime;
  final String endTime;
  final String status;
  final String semester;
  final String classID;
  final String yearLevel;
  final String section;
  final String profId;
  final Iterable sessions;

  const ClassDetailsPage({
    super.key,
    required this.subject,
    required this.courseCode,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.semester,
    required this.classID,
    required this.yearLevel,
    required this.section,
    required this.profId,
    required this.sessions,
  });

  @override
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage>
    with WidgetsBindingObserver {
  final db = AppDatabase.instance;

  List<Map<String, dynamic>> students = [];

  int activeSessionID = 0;
  int _sessionsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    getAllStudents();
    _checkForOngoingSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh session state when app resumes
      _refreshSessionState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh when dependencies actually change, not on every build
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshSessionState();
        }
      });
    }
  }

  Future<void> _checkForOngoingSession() async {
    final session = await AppDatabase.instance.checkForOngoingSession(
      int.parse(widget.classID),
    );
    if (session.isNotEmpty) {
      debugPrint("Ongoing Found: ${session.first.id}");
      setState(() {
        activeSessionID = int.parse(session.first.id.toString());
      });
    } else {
      setState(() {
        activeSessionID = 0;
      });
    }
  }

  Future<void> _refreshSessionState() async {
    await _checkForOngoingSession();
    await _loadSessionsCount();
  }

  void getAllStudents() async {
    final studentsData = await AppDatabase.instance.getStudentsInSubject(
      int.parse(widget.classID),
    );

    setState(() {
      students = studentsData.map((student) => student.toJson()).toList();
    });
  }

  Future<void> _loadSessionsCount() async {
    try {
      final sessions = await AppDatabase.instance.getSessionsBySubjectId(
        int.parse(widget.classID),
      );
      if (mounted) {
        setState(() {
          _sessionsCount = sessions.length;
        });
      }
    } catch (e) {
      debugPrint('Failed to load sessions count: $e');
      if (mounted) {
        setState(() {
          _sessionsCount = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _ClassDetailsAppBar(
        subjectId: widget.classID,
        subjectData: {
          'id': int.parse(widget.classID),
          'subjectName': widget.subject,
          'subjectCode': widget.courseCode,
          'yearLevel': widget.yearLevel,
          'section': widget.section,
        },
        scheduleData: widget.sessions
            .map(
              (session) => {
                'day': session['day'] ?? '',
                'startTime': session['startTime'] ?? '',
                'endTime': session['endTime'] ?? '',
                'room': session['room'] ?? '',
              },
            )
            .toList(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClassDetailsInfoCard(
              subject: widget.subject,
              courseCode: widget.courseCode,
              room: widget.room,
              startTime: widget.startTime,
              endTime: widget.endTime,
              semester: widget.semester,
              yearLevel: widget.yearLevel,
              section: widget.section,
              profId: widget.profId,
              sessions: widget.sessions,
            ),
            const SizedBox(height: 12),
            _QuickActionsSection(
              classID: widget.classID,
              activeSessionID: activeSessionID,
              onRefreshSessionState: _refreshSessionState,
            ),
            const SizedBox(height: 24),
            _FeatureListSection(
              classID: widget.classID,
              students: students,
              sessionsCount: _sessionsCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String subjectId;
  final Map<String, dynamic> subjectData;
  final List<Map<String, dynamic>> scheduleData;

  const _ClassDetailsAppBar({
    required this.subjectId,
    required this.subjectData,
    required this.scheduleData,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: scheme.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: scheme.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Class Details',
        style: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.more_vert, color: scheme.onSurface),
          onPressed: () => _showMenu(context),
        ),
      ],
    );
  }

  void _showMenu(BuildContext context) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 0, 0),
      items: [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit Subject'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Subject', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((selection) {
      if (selection == 'edit') {
        _editSubject(context);
      } else if (selection == 'delete') {
        _deleteSubject(context);
      }
    });
  }

  void _editSubject(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddSubjectPage(
          existingSubject: subjectData,
          existingSchedules: scheduleData,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Navigate back to refresh the page
        Navigator.pop(context, true);
      }
    });
  }

  void _deleteSubject(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: const Text('This will remove the subject and its schedules.'),
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

    if (confirm == true) {
      try {
        await AppDatabase.instance.deleteSubject(int.parse(subjectId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete subject: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _QuickActionsSection extends StatelessWidget {
  final String classID;
  final int activeSessionID;
  final VoidCallback onRefreshSessionState;
  const _QuickActionsSection({
    required this.classID,
    required this.activeSessionID,
    required this.onRefreshSessionState,
  });

  @override
  Widget build(BuildContext context) {
    Future<void> confirmStartSession(BuildContext context) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: activeSessionID == 0
              ? const Text('Start Session?')
              : const Text('Resume Session?'),
          content: const Text('Are you sure you want to Start Session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Start'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        debugPrint(
          '${activeSessionID == 0 ? 'Start' : 'Resume'} Session confirmed for class: $classID',
        );
        if (context.mounted) {
          String sessionID;

          if (activeSessionID == 0) {
            // Create new session
            final newSessionID = await AppDatabase.instance.insertSession(
              SessionsCompanion(
                subjectId: drift.Value(int.parse(classID)),
                startTime: drift.Value(DateTime.now()),
                endTime: drift.Value(DateTime.now()),
                status: drift.Value('ongoing'),
                synced: drift.Value(false),
                createdAt: drift.Value(DateTime.now()),
              ),
            );
            sessionID = newSessionID.toString();
            debugPrint('New Session ID: $sessionID');
          } else {
            // Use existing session
            sessionID = activeSessionID.toString();
            debugPrint('Resuming Session ID: $sessionID');
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AttendancePage(subjectId: classID, sessionID: sessionID),
            ),
          ).then((result) {
            // Refresh session state when returning from attendance page
            if (result == 'session_ended') {
              debugPrint('Session was ended, refreshing state...');
            }
            onRefreshSessionState();
          });
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.grid_view,
                  label: activeSessionID == 0
                      ? 'Start Session'
                      : 'Resume Session',
                  isPrimary: true,
                  onTap: () => confirmStartSession(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.calendar_today,
                  label: 'Schedule Class',
                  isPrimary: false,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isPrimary ? scheme.primary : scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            border: isPrimary ? null : Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureListSection extends StatelessWidget {
  final String classID;
  final List<Map<String, dynamic>> students;
  final int sessionsCount;
  const _FeatureListSection({
    required this.classID,
    required this.students,
    required this.sessionsCount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _FeatureListItem(
            icon: Icons.people,
            title: 'Students List',
            description: 'Manage enrolled students',
            trailing: students.length.toString(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentPage(subjectId: classID),
                ),
              );
            },
          ),
          const _Divider(),
          _FeatureListItem(
            icon: Icons.trending_up,
            title: 'Attendance History',
            description: 'View attendance analytics',
            trailing: '87%',
            onTap: () => debugPrint('Attendance History'),
          ),
          const _Divider(),
          _FeatureListItem(
            icon: Icons.calendar_month,
            title: 'Class Sessions',
            description: 'View all session records',
            trailing: sessionsCount.toString(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SessionPage(subjectId: classID),
                ),
              );
            },
          ),
          const _Divider(),
          // _FeatureListItem(
          //   icon: Icons.schedule,
          //   title: 'Schedule',
          //   description: 'Manage class timetable',
          //   trailing: '',
          //   onTap: () => debugPrint('Schedule'),
          // ),
          // const _Divider(),
          _FeatureListItem(
            icon: Icons.assignment,
            title: 'Reports',
            description: 'Generate attendance reports',
            trailing: '',
            onTap: () => debugPrint('Reports'),
          ),
          const _Divider(),
          _FeatureListItem(
            icon: Icons.settings,
            title: 'Class Settings',
            description: 'Configure class preferences',
            trailing: '',
            onTap: () => debugPrint('Class Settings'),
          ),
        ],
      ),
    );
  }
}

class _FeatureListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String trailing;
  final VoidCallback onTap;

  const _FeatureListItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: scheme.onSurfaceVariant, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: scheme.onSurface,
        ),
      ),
      subtitle: Text(
        description,
        style: TextStyle(
          color: scheme.onSurface.withOpacity(0.7),
          fontSize: 13,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, color: scheme.outline, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: scheme.outlineVariant,
    );
  }
}
