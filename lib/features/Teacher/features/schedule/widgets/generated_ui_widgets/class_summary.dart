import 'package:flutter/material.dart';

class ClassSummaryCard extends StatelessWidget {
  final String classID;
  final String subject;

  const ClassSummaryCard({
    super.key,
    required this.classID,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school, color: scheme.onPrimary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            'Class $classID',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          Text(
            subject, // ✅ FIXED: use from classDetails
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Spring Semester 2025', // optionally use widget.semester instead
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: const [
          //     _StatItem(number: '124', label: 'Students'),
          //     _StatItem(number: '32', label: 'Sessions'),
          //     _StatItem(number: '87%', label: 'Avg Rate'),
          //   ],
          // ),
        ],
      ),
    );
  }
}
