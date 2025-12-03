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
  // Bulk delete state
  bool _bulkMode = false;
  final Set<int> _selectedIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    debugPrint(
      '🔄 [SESSION LOADING] Loading sessions for subject ID: ${widget.subjectId}',
    );
    setState(() => _loading = true);
    try {
      final sessions = await db.getSessionsBySubjectId(
        int.parse(widget.subjectId),
      );
      debugPrint('📊 [SESSION DATA] Loaded ${sessions.length} sessions');

      Subject? subject;
      Term? term;
      try {
        final subjectList = await db.getSubjectByID(
          int.parse(widget.subjectId),
        );
        if (subjectList.isNotEmpty) {
          subject = subjectList.first;
          debugPrint(
            '🏫 [SUBJECT DATA] Subject: ${subject.subjectName} (${subject.subjectCode})',
          );
          term = await db.getTermById(subject.termId);
          debugPrint('📚 [TERM DATA] Term: ${term?.term} ${term?.startYear}');
        }
      } catch (_) {}

      // Log each session's details
      for (var session in sessions) {
        debugPrint(
          '   📅 Session ${session.id}: ${session.status} from ${session.startTime.toIso8601String()}',
        );
        if (session.endTime != null) {
          debugPrint('      End: ${session.endTime!.toIso8601String()}');
        }
      }

      setState(() {
        _sessions = sessions;
        _subject = subject;
        _term = term;
      });
      _applyFilters();
      debugPrint('✅ [SESSION LOADING] Sessions loaded successfully');
    } catch (e) {
      debugPrint('❌ [SESSION LOADING] Failed to load sessions: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<int> _getAttendanceCount(int sessionId) async {
    final attendance = await db.getAttendanceBySessionID(sessionId);
    return attendance
        .where((a) => a.status.toLowerCase() == 'present')
        .length;
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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: scheme.onSurface),
            onSelected: (value) {
              if (value == 'bulk_delete') {
                setState(() {
                  _bulkMode = true;
                  _selectedIds.clear();
                });
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'bulk_delete',
                child: Text('Delete sessions'),
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
                                debugPrint(
                                  '🎯 [SESSION INTERACTION] Session tapped:',
                                );
                                debugPrint(
                                  '   📊 Session Data: id=${s.id}, status=${s.status}',
                                );
                                debugPrint(
                                  '   📅 Start Time: ${s.startTime.toIso8601String()}',
                                );
                                debugPrint(
                                  '   📅 End Time: ${s.endTime?.toIso8601String() ?? 'null'}',
                                );
                                debugPrint('   👥 Attendance Count: $count');
                                debugPrint(
                                  '   🏫 Subject: ${_subject?.subjectName ?? 'Unknown'}',
                                );
                                debugPrint(
                                  '   📚 Term: ${_term?.term ?? 'Unknown'} ${_term?.startYear ?? ''}',
                                );

                                if (_bulkMode) {
                                  debugPrint(
                                    '📦 [BULK MODE] Toggling selection for session ${s.id}',
                                  );
                                  _toggleSelect(
                                    s.id,
                                    !_selectedIds.contains(s.id),
                                  );
                                  return;
                                }

                                debugPrint(
                                  '🔍 [SESSION NAVIGATION] Navigating to attendance page for session ${s.id}',
                                );
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

                                        if (_bulkMode)
                                          Checkbox(
                                            value: _selectedIds.contains(s.id),
                                            onChanged: (v) =>
                                                _toggleSelect(s.id, v ?? false),
                                          )
                                        else
                                          Text(
                                            statusLabel,
                                            style: TextStyle(
                                              color: scheme.onSurface
                                                  .withOpacity(0.7),
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
                                          '$count present',
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
          if (_bulkMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _bulkMode = false;
                        _selectedIds.clear();
                      });
                    },
                    child: const Text('Cancel'),
                  ),

                  ElevatedButton.icon(
                    onPressed: _selectedIds.isEmpty ? null : _confirmBulkDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.delete),
                    label: Text('Delete (${_selectedIds.length})'),
                  ),
                ],
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

  void _toggleSelect(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  Future<void> _confirmBulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete selected sessions?'),
        content: Text(
          'This will delete ${_selectedIds.length} session(s) and their attendance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // delete sequentially to keep it simple
        for (final id in _selectedIds) {
          await db.deleteSessionById(id);
        }
        await _loadSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected sessions deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete sessions: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _bulkMode = false;
            _selectedIds.clear();
          });
        }
      }
    }
  }

  Future<void> _confirmDeleteSession(
    BuildContext context,
    int sessionId,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete session?'),
        content: const Text(
          'This will permanently remove the session and its attendance records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await db.deleteSessionById(sessionId);
        await _loadSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
