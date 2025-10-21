import 'package:flutter/material.dart';
import 'package:myattendance/features/Teacher/features/class_details/pages/class_details_page.dart';
import 'package:myattendance/features/Teacher/features/schedule/pages/add_subject_page.dart';
import 'package:myattendance/core/database/app_database.dart';

class ClassCard extends StatefulWidget {
  final String subject;
  final String courseCode;
  final String room;
  final String startTime;
  final String endTime;
  final String status;
  final String semester;
  final String classID;
  final Iterable sessions;
  final String yearLevel;
  final String section;
  final String profId;
  final int? subjectId;
  final VoidCallback reloadStates;
  final Map<String, dynamic>? subjectData;
  final List<Map<String, dynamic>>? scheduleData;

  const ClassCard({
    super.key,
    required this.subject,
    required this.courseCode,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.semester,
    required this.classID,
    required this.sessions,
    required this.yearLevel,
    required this.section,
    required this.profId,
    required this.subjectId,
    required this.reloadStates,
    this.subjectData,
    this.scheduleData,
  });
  @override
  State<ClassCard> createState() => _ClassCardState();
}

class _ClassCardState extends State<ClassCard> {
  int _studentCount = 0;
  int _sessionCount = 0;
  double? _avgAttendancePercent;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = AppDatabase.instance;
    final sid = widget.subjectId;
    if (sid == null) return;

    try {
      final students = await db.getStudentsInSubject(sid);
      final sessions = await db.getSessionsBySubjectId(sid);

      // Compute average attendance by session: for each session,
      // percent = present_count / enrolled_students. Then average those percents.
      final enrolled = students.length;
      double sumSessionPercents = 0.0;
      int countedSessions = 0;

      if (enrolled > 0) {
        for (final s in sessions) {
          final attendances = await db.getAttendanceBySessionID(s.id);
          int presentThisSession = 0;
          for (final a in attendances) {
            final status = a.status.toString().toLowerCase();
            if (status == 'present' || status == 'presented' || status == 'p') {
              presentThisSession += 1;
            }
          }
          // session percent based on enrolled students
          final sessionPercent = (presentThisSession / enrolled) * 100;
          sumSessionPercents += sessionPercent;
          countedSessions += 1;
        }
      }

      setState(() {
        _studentCount = students.length;
        _sessionCount = sessions.length;
        _avgAttendancePercent = countedSessions > 0
            ? (sumSessionPercents / countedSessions)
            : null;
      });
    } catch (e) {
      debugPrint('Error loading class stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassDetailsPage(
              subject: widget.subject,
              classID: widget.subjectId
                  .toString(), // Use subjectId instead of classID
              courseCode: widget.courseCode,
              sessions: widget.sessions,
              room: widget.room,
              startTime: widget.startTime,
              endTime: widget.endTime,
              status: 'SCHEDULED',
              semester: widget.semester,
              yearLevel: widget.yearLevel,
              section: widget.section,
              profId: widget.profId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with icon, title, and next session
                Row(
                  children: [
                    // Subject Icon
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getSubjectIcon(widget.subject),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Course Title and Semester
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subject,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.semester,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right Section - Next Session Information (no menu here)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Status Indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Next Session Time
                        Text(
                          'Next: ${_formatTo12Hour(widget.startTime)}', // TODO: Replace with actual next session time calculation
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Statistics Row - Full Width
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_studentCount Students',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        '$_sessionCount Sessions',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        _avgAttendancePercent != null
                            ? '${_avgAttendancePercent!.toStringAsFixed(0)}% Avg'
                            : 'N/A',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              top: 0,
              right: 0,
              child: InkWell(
                onTap: () async {
                  final RenderBox button =
                      context.findRenderObject() as RenderBox;
                  final RenderBox overlay =
                      Overlay.of(context).context.findRenderObject()
                          as RenderBox;

                  final Offset buttonPosition = button.localToGlobal(
                    Offset.zero,
                    ancestor: overlay,
                  );

                  final RelativeRect position = RelativeRect.fromRect(
                    Rect.fromLTWH(
                      buttonPosition.dx + 30,
                      buttonPosition.dy - 10,
                      button.size.width + 40,
                      button.size.height + 60,
                    ),
                    Offset.zero & overlay.size,
                  );

                  final selection = await showMenu<String>(
                    context: context,
                    position: position,
                    color: Colors.white,
                    items: const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Subject'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Delete Subject',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (selection == 'edit') {
                    if (context.mounted && widget.subjectData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddSubjectPage(
                            existingSubject: widget.subjectData,
                            existingSchedules: widget.scheduleData,
                          ),
                        ),
                      ).then((result) {
                        if (result == true) {
                          widget.reloadStates();
                        }
                      });
                    }
                  } else if (selection == 'delete') {
                    debugPrint("Deleted subject ${widget.subjectId}");
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Subject?'),
                        content: const Text(
                          'This will remove the subject and its schedules.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => {Navigator.pop(ctx, true)},
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && widget.subjectId != null) {
                      try {
                        await AppDatabase.instance.deleteSubject(
                          widget.subjectId!,
                        );
                        widget.reloadStates();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Subject deleted successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Success message shown, no navigation needed
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
                },
                child: const Icon(
                  Icons.more_horiz,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTo12Hour(String timeString) {
    if (timeString.isEmpty || timeString == 'Unknown') {
      return timeString;
    }

    try {
      // Handle different time formats
      if (timeString.contains(':')) {
        // Parse time string (e.g., "09:00", "14:30", "9:00 AM")
        List<String> parts = timeString.split(':');
        if (parts.length >= 2) {
          int hour = int.parse(parts[0]);
          String minutes = parts[1].split(
            ' ',
          )[0]; // Remove AM/PM if already present

          // If already in 12-hour format, return as is
          if (timeString.toUpperCase().contains('AM') ||
              timeString.toUpperCase().contains('PM')) {
            return timeString;
          }

          String period = hour >= 12 ? 'PM' : 'AM';
          int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

          return '$displayHour:$minutes $period';
        }
      }

      // If parsing fails, return original string
      return timeString;
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return timeString;
    }
  }

  IconData _getSubjectIcon(String subject) {
    // Map subject names to appropriate icons
    final subjectLower = subject.toLowerCase();

    if (subjectLower.contains('math') ||
        subjectLower.contains('calculus') ||
        subjectLower.contains('algebra')) {
      return Icons.calculate;
    } else if (subjectLower.contains('physics')) {
      return Icons.science;
    } else if (subjectLower.contains('chemistry')) {
      return Icons.biotech;
    } else if (subjectLower.contains('computer') ||
        subjectLower.contains('programming') ||
        subjectLower.contains('software')) {
      return Icons.computer;
    } else if (subjectLower.contains('biology') ||
        subjectLower.contains('life')) {
      return Icons.eco;
    } else if (subjectLower.contains('english') ||
        subjectLower.contains('literature') ||
        subjectLower.contains('writing')) {
      return Icons.menu_book;
    } else if (subjectLower.contains('history') ||
        subjectLower.contains('social')) {
      return Icons.history_edu;
    } else if (subjectLower.contains('art') ||
        subjectLower.contains('design')) {
      return Icons.palette;
    } else if (subjectLower.contains('music')) {
      return Icons.music_note;
    } else if (subjectLower.contains('business') ||
        subjectLower.contains('economics')) {
      return Icons.business;
    } else {
      return Icons.school; // Default icon
    }
  }
}
