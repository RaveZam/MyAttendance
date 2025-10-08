import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/core/database/app_database.dart';

class AttendancePerSessionPage extends StatefulWidget {
  final String sessionId;

  const AttendancePerSessionPage({super.key, required this.sessionId});

  @override
  State<AttendancePerSessionPage> createState() =>
      _AttendancePerSessionPageState();
}

class _AttendancePerSessionPageState extends State<AttendancePerSessionPage> {
  final db = AppDatabase.instance;
  bool _loading = true;
  List<AttendanceData> _attendances = [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _loading = true);
    try {
      final list = await db.getAttendanceBySessionID(
        int.parse(widget.sessionId),
      );
      // Only show present
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _attendances = list
            .where((a) => a.status.toLowerCase() == 'present')
            .toList();
      });
    } catch (e) {
      debugPrint('Failed to load attendance: $e');
    } finally {
      setState(() => _loading = false);
    }
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
          'Attendance',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: scheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadAttendance,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  _buildSummaryRow(scheme),
                  const SizedBox(height: 12),
                  Text(
                    'Present (${_attendances.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._attendances.map((a) => _AttendanceTile(data: a)).toList(),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryRow(ColorScheme scheme) {
    final present = _attendances.length;
    final absent = 0; // not tracked in this simple view
    final late = 0; // not tracked in this simple view
    return Row(
      children: [
        _summaryBox(scheme, present.toString(), 'Present'),
        const SizedBox(width: 12),
        _summaryBox(scheme, absent.toString(), 'Absent'),
        const SizedBox(width: 12),
        _summaryBox(scheme, late.toString(), 'Late'),
      ],
    );
  }

  Widget _summaryBox(ColorScheme scheme, String value, String label) {
    return Expanded(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  final AttendanceData data;
  const _AttendanceTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final time = DateFormat('h:mm a').format(data.createdAt.toLocal());
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${data.studentId}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Present',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Present',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
