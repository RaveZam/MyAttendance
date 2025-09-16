import 'package:flutter/material.dart';

class DisplayNextClass extends StatelessWidget {
  const DisplayNextClass({super.key});

  @override
  Widget build(BuildContext context) {
    const String label = 'NEXT CLASS';
    const String timeRange = '11:45 AM - 1:15 PM';
    const String title = 'Physics - Grade 11B';
    const String room = 'Lab 3';
    const int studentsCount = 25;
    const String startsIn = 'Starts in 15 minutes';

    return Stack(
      children: [
        // Card
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      label,
                      style: TextStyle(
                        color: Color(0xFFB45309), // amber-700 like
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeRange,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildSubtitle(room, studentsCount),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        startsIn,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF111827),
                        side: BorderSide(color: Colors.grey[300]!),
                        backgroundColor: Colors.grey[100],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Prepare'),
                    ),
                  ],
                ),
              ],
            ),
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
                colors: [const Color(0xFFF59E0B), const Color(0xFFFDE68A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _buildSubtitle(String room, int students) {
    final roomText = room.isNotEmpty ? room : '';
    final studentsText = '• $students students';
    if (roomText.isEmpty) return studentsText.replaceFirst('• ', '');
    return '$roomText $studentsText';
  }
}
