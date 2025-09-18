import 'package:flutter/material.dart';

class DisplayNextClass extends StatelessWidget {
  const DisplayNextClass({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data (static UI)
    const subject = 'Data Structures';
    const subtitle = 'Advanced Algorithms';
    const timeRange = '11:00 AM - 12:30 PM';
    const room = 'Room 301';
    const startsIn = 'Starts in 30 min';

    return Stack(
      children: [
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'UPCOMING',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    room,
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                subject,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                subtitle,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.access_time, size: 16, color: Color(0xFF374151)),
                  SizedBox(width: 8),
                  Text(
                    timeRange,
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Spacer(),
                  Text(
                    startsIn,
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: 16,
          bottom: 16,
          child: Container(
            width: 6,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              gradient: LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
