import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/features/Teacher/features/attendance/pages/attendance_per_session.dart';

class SessionPage extends StatefulWidget {
  final String subjectId;

  const SessionPage({super.key, required this.subjectId});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  final db = AppDatabase.instance;
  bool _loading = true;
  List<Session> _sessions = [];
  Subject? _subject;
  Term? _term;
  // Sort state
  bool _sortDesc = true; // newest to oldest by default
  List<Session> _filteredSessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    try {
      final sessions = await db.getSessionsBySubjectId(
        int.parse(widget.subjectId),
      );
      Subject? subject;
      Term? term;
      try {
        final subjectList = await db.getSubjectByID(
          int.parse(widget.subjectId),
        );
        if (subjectList.isNotEmpty) {
          subject = subjectList.first;
          term = await db.getTermById(subject.termId);
        }
      } catch (_) {}

      setState(() {
        _sessions = sessions;
        _subject = subject;
        _term = term;
      });
      _applyFilters();
    } catch (e) {
      debugPrint('Failed to load sessions: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<int> _getAttendanceCount(int sessionId) async {
    final attendance = await db.getAttendanceBySessionID(sessionId);
    return attendance.length;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Class Sessions',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: scheme.onSurface),
            onSelected: (value) {
              setState(() {
                _sortDesc = value == 'newest';
              });
              _applyFilters();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16),
                    SizedBox(width: 8),
                    Text('Newest to oldest'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 16),
                    SizedBox(width: 8),
                    Text('Oldest to newest'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: scheme.surface,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSessions,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredSessions.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Icon(Icons.event_busy, size: 56, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text('No sessions found for this class'),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final s = _filteredSessions[index];
                        return FutureBuilder<int>(
                          future: _getAttendanceCount(s.id),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            final start = s.startTime.toLocal();
                            final end = s.endTime?.toLocal();
                            final termLabel = _term != null
                                ? '${_term!.term} ${_term!.startYear}'
                                : 'Term';
                            final statusLabel = s.status == 'completed'
                                ? 'Completed'
                                : (s.status == 'ongoing'
                                      ? 'Ongoing'
                                      : s.status);
                            final dateLabel = DateFormat(
                              'MMM d, yyyy',
                            ).format(start);
                            final duration = end != null
                                ? end.difference(start)
                                : null;
                            final durationLabel = duration != null
                                ? _formatDuration(duration)
                                : 'Ongoing';

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AttendancePerSessionPage(
                                          sessionId: s.id.toString(),
                                        ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: scheme.outline.withOpacity(0.2),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Top row: chip, dot, term, spacer, status
                                    Row(
                                      children: [
                                        _buildChip(
                                          _subject?.subjectCode ?? 'CODE',
                                          scheme,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildDot(scheme),
                                        const SizedBox(width: 8),
                                        Text(
                                          termLabel,
                                          style: TextStyle(
                                            color: scheme.onSurface.withOpacity(
                                              0.75,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          statusLabel,
                                          style: TextStyle(
                                            color: scheme.onSurface.withOpacity(
                                              0.7,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 10),

                                    // Title
                                    Text(
                                      _subject?.subjectName ??
                                          'Session ${s.id}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    // Subtitle (placeholder chapter line)
                                    Text(
                                      'Chapter 5: Integration Techniques',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: scheme.onSurface.withOpacity(
                                          0.75,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Footer: date, duration, students
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: scheme.onSurface.withOpacity(
                                            0.7,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          dateLabel,
                                          style: TextStyle(
                                            color: scheme.onSurface.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: scheme.onSurface.withOpacity(
                                            0.7,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          durationLabel,
                                          style: TextStyle(
                                            color: scheme.onSurface.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.group,
                                          size: 16,
                                          color: scheme.onSurface.withOpacity(
                                            0.7,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$count students',
                                          style: TextStyle(
                                            color: scheme.onSurface.withOpacity(
                                              0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: _filteredSessions.length,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    List<Session> working = List.of(_sessions);

    _sortSessions(working, _sortDesc);
    setState(() {
      _filteredSessions = working;
    });
  }

  void _sortSessions(List<Session> list, bool desc) {
    list.sort((a, b) {
      final at = a.startTime;
      final bt = b.startTime;
      final cmp = at.compareTo(bt);
      return desc ? -cmp : cmp;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}

Widget _buildDot(ColorScheme scheme) {
  return Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(
      color: scheme.onSurface.withOpacity(0.6),
      shape: BoxShape.circle,
    ),
  );
}

Widget _buildChip(String label, ColorScheme scheme) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: scheme.surfaceVariant,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: scheme.onSurface,
      ),
    ),
  );
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
  if (hours > 0) return '${hours}h';
  return '${minutes}m';
}
