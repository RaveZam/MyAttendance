import 'package:flutter/material.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's Overview",
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.today, size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Today',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _CompactStatCard(
                    icon: Icons.calendar_today,
                    iconColor: Color(0xFF2563EB),
                    label: 'Classes',
                    value: '5',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _CompactStatCard(
                    icon: Icons.insights,
                    iconColor: Color(0xFF10B981),
                    label: 'Attendance',
                    value: '92%',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _CompactStatCard(
                    icon: Icons.groups,
                    iconColor: Color(0xFF059669),
                    label: 'Students',
                    value: '128',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _CompactStatCard(
                    icon: Icons.verified,
                    iconColor: Color(0xFFF59E0B),
                    label: 'Present',
                    value: '118',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _CompactStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
