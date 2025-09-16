import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:myattendance/core/logic/schedule_filter.dart';

class DisplayCurrentClass extends StatefulWidget {
  const DisplayCurrentClass({super.key});

  @override
  State<DisplayCurrentClass> createState() => _DisplayCurrentClassState();
}

class _DisplayCurrentClassState extends State<DisplayCurrentClass> {
  final ScheduleFilter currentClass = ScheduleFilter();
  final currentClassSubject = '';

  Future<void> setCurrentClass() async {
    // debugPrint('Current Class: ${await currentClass.getCurrentClass()}');
  }

  @override
  void initState() {
    super.initState();
    setCurrentClass();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Schedule>>(
      future: ScheduleFilter().getCurrentClass(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingCard();
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Something went wrong. Please try again.',
              style: TextStyle(color: Colors.red[600]),
            ),
          );
        }

        final items = snapshot.data ?? const <Schedule>[];
        if (items.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'No class live at the moment',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final current = items.first;
        return _CurrentClassCard(schedule: current);
      },
    );
  }
}

class _LoadingCard extends StatefulWidget {
  const _LoadingCard();

  @override
  State<_LoadingCard> createState() => _LoadingCardState();
}

class _LoadingCardState extends State<_LoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(width: 10, height: 10, radius: 5),
                  const SizedBox(width: 8),
                  _shimmerBox(width: 70, height: 12, radius: 4),
                  const Spacer(),
                  _shimmerBox(width: 110, height: 12, radius: 4),
                ],
              ),
              const SizedBox(height: 16),
              _shimmerBox(width: 200, height: 16, radius: 6),
              const SizedBox(height: 8),
              _shimmerBox(width: 140, height: 14, radius: 6),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Spacer(),
                  _shimmerBox(width: 140, height: 36, radius: 10),
                ],
              ),
            ],
          ),
        ),
        // Thick left border
        Positioned(
          left: 16,
          top: 16,
          bottom: 16,
          child: Container(
            width: 6,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade200],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shimmerBox({
    required double width,
    required double height,
    double radius = 8,
  }) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  // Removed circle shimmer helper as avatars are not shown in the new design
}

class _CurrentClassCard extends StatelessWidget {
  final Schedule schedule;

  const _CurrentClassCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red.shade300,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE NOW',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    schedule.time,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                schedule.subject,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _buildSubtitle(schedule),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Take Attendance'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Thick left border
        Positioned(
          left: 16,
          top: 16,
          bottom: 16,
          child: Container(
            width: 8,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFFE57373), Color(0xFFFFCDD2)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildSubtitle(Schedule s) {
    final roomText = s.room.isNotEmpty ? 'Room ${s.room}' : '';
    // Placeholder students count to match the reference UI
    final students = '• 28 students';
    if (roomText.isEmpty) return students.replaceFirst('• ', '');
    return '$roomText $students';
  }
}

// Removed Avatar widget as avatars are not shown in the new design
