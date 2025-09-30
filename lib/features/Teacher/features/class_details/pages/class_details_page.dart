import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/features/Teacher/features/schedule/widgets/generated_ui_widgets/class_summary.dart';
import 'package:myattendance/features/Teacher/features/students_list/pages/student_page.dart';

class ClassDetailsPage extends StatefulWidget {
  final String subject;
  final String courseCode;
  final String room;
  final String startTime;
  final String endTime;
  final String status;
  final String semester;
  final String classID;
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
    required this.sessions,
  });

  @override
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  final db = AppDatabase.instance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: const _ClassDetailsAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ClassSummaryCard(classID: widget.classID, subject: widget.subject),
            const SizedBox(height: 12),
            const SizedBox(height: 24),
            const _QuickActionsSection(),
            const SizedBox(height: 24),
            const _FeatureListSection(),
          ],
        ),
      ),
    );
  }
}

class _ClassDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ClassDetailsAppBar();

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
          onPressed: () {
            // TODO: menu options
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
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
                  label: 'Start Session',
                  isPrimary: true,
                  onTap: () {},
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
  const _FeatureListSection();

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
            trailing: '124',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StudentPage()),
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
            trailing: '32',
            onTap: () => debugPrint('Class Sessions'),
          ),
          const _Divider(),
          _FeatureListItem(
            icon: Icons.schedule,
            title: 'Schedule',
            description: 'Manage class timetable',
            trailing: '',
            onTap: () => debugPrint('Schedule'),
          ),
          const _Divider(),
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
