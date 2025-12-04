import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class Qrcode extends StatelessWidget {
  final Map<String, dynamic>? classData;
  final Widget? footer;

  const Qrcode({super.key, this.classData, this.footer});

  static const Map<String, dynamic> _fallbackData = {
    "class_code": "CS101",
    "class_name": "Introduction to Computer Science",
    "class_session_id": "2025-09-03-10AM",
    "instructor_name": "Instructor",
    "start_time": "10:00 AM",
    "end_time": "11:00 AM",
    "day": "Monday",
  };

  @override
  Widget build(BuildContext context) {
    final data = {..._fallbackData, ...?classData};
    final className = (data["class_name"] ?? "Class Name").toString();
    final classCode = (data["class_code"] ?? "CLASS101").toString();
    final section = (data["section"] ?? "").toString().trim();
    final yearLevel = (data["year_level"] ?? "").toString().trim();
    final day = (data["day"] ?? "").toString();
    final start = (data["start_time"] ?? "-").toString();
    final end = (data["end_time"] ?? "-").toString();
    final detailParts = [
      if (classCode.isNotEmpty) classCode,
      if (section.isNotEmpty) section,
      if (day.isNotEmpty) day,
    ];
    final detailLine = detailParts.join(' • ');

    final jsonString = jsonEncode(data);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            className,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(
                            detailLine.isEmpty ? classCode : detailLine,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrettyQrView.data(
                data: jsonString,
                decoration: const PrettyQrDecoration(
                  quietZone: PrettyQrQuietZone.standart,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTimeInfo("Start", start, Colors.green),
                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    _buildTimeInfo("End", end, Colors.red),
                  ],
                ),
              ),
              if (yearLevel.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Year Level: $yearLevel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (footer != null) ...[const SizedBox(height: 16), footer!],
      ],
    );
  }

  Widget _buildTimeInfo(String label, String time, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
