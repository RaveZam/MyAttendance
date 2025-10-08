import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';

class AttendanceList extends StatefulWidget {
  final String sessionID;
  final List<AttendanceData> attendanceList;
  const AttendanceList({
    super.key,
    required this.sessionID,
    required this.attendanceList,
  });

  @override
  State<AttendanceList> createState() => _AttendanceListState();
}

class _AttendanceListState extends State<AttendanceList> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.people, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Attended Students',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.attendanceList.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: scheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Loading attendance...',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : widget.attendanceList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 48,
                          color: scheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No students attended yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Scan QR codes to mark attendance',
                          style: TextStyle(
                            fontSize: 14,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: widget.attendanceList.length,
                    itemBuilder: (context, index) {
                      final attendance = widget.attendanceList[index];
                      return _buildAttendanceItem(attendance, scheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceItem(AttendanceData attendance, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student ID: ${attendance.studentId}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        attendance.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatTime(attendance.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
