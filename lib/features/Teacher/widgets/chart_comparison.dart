import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/core/database/app_database.dart';

class ChartComparison extends StatefulWidget {
  const ChartComparison({super.key});

  @override
  State<ChartComparison> createState() => _ChartComparisonState();
}

class _ChartComparisonState extends State<ChartComparison> {
  final List<int> _presentCounts = [];
  final List<int> _absentCounts = [];
  final List<String> _dayLabels = [];
  final List<DateTime> _dayDates = [];
  double _maxValue = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeeklyTrend();
  }

  Future<void> _loadWeeklyTrend() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase.instance;
      final now = DateTime.now();
      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      final allSessions = await (db.select(db.sessions)).get();
      final weekSessions = allSessions.where((session) {
        final sessionDate = session.startTime;
        return sessionDate.isAfter(
              startOfWeek.subtract(const Duration(seconds: 1)),
            ) &&
            sessionDate.isBefore(endOfWeek.add(const Duration(seconds: 1)));
      }).toList();

      final sessionIds = weekSessions.map((s) => s.id).toList();
      final attendance = sessionIds.isNotEmpty
          ? await db.getAttendanceBySessionIds(sessionIds)
          : <AttendanceData>[];

      _presentCounts.clear();
      _absentCounts.clear();
      _dayLabels.clear();
      _dayDates.clear();
      _maxValue = 0;

      for (var index = 0; index < 7; index++) {
        final day = startOfWeek.add(Duration(days: index));
        // Skip Saturday (6) and Sunday (7)
        if (day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          continue;
        }

        final daySessionIds = weekSessions
            .where((s) => _isSameDay(s.startTime, day))
            .map((s) => s.id)
            .toSet();
        final dayAttendance = attendance
            .where((a) => daySessionIds.contains(a.sessionId))
            .toList();

        final presentCount = dayAttendance.where((a) {
          final status = a.status.toLowerCase();
          return status == 'present' || status == 'late';
        }).length;

        final absentCount = dayAttendance
            .where((a) => a.status.toLowerCase() == 'absent')
            .length;

        _presentCounts.add(presentCount);
        _absentCounts.add(absentCount);
        _dayLabels.add(DateFormat.E().format(day));
        _dayDates.add(day);
        _maxValue = max(_maxValue, max(presentCount, absentCount).toDouble());
      }

      if (_maxValue < 5) {
        _maxValue = 5;
      }
    } catch (e) {
      debugPrint('Failed to load weekly trend: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Attendance Trend',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _isLoading
              ? const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              : SizedBox(
                  height: 150,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: max(_maxValue, 5),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: max(
                          1,
                          (_maxValue / 5).clamp(1, 10),
                        ),
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          axisNameSize: 22,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              final label =
                                  index >= 0 && index < _dayLabels.length
                                  ? _dayLabels[index]
                                  : '';
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: scheme.onSurface.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: max(
                              1,
                              (_maxValue / 4).clamp(1, double.infinity),
                            ),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: scheme.onSurface.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 32,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(_dayLabels.length, (index) {
                        return BarChartGroupData(
                          x: index,
                          groupVertically: false,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: index < _presentCounts.length
                                  ? _presentCounts[index].toDouble()
                                  : 0,
                              color: scheme.primary,
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: index < _absentCounts.length
                                  ? _absentCounts[index].toDouble()
                                  : 0,
                              color: Colors.red.shade700,
                              width: 12,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }),
                      groupsSpace: 8,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => Colors.white,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(8),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final index = group.x.toInt();
                            final present = index < _presentCounts.length
                                ? _presentCounts[index]
                                : 0;
                            final absent = index < _absentCounts.length
                                ? _absentCounts[index]
                                : 0;

                            return BarTooltipItem(
                              '',
                              const TextStyle(),
                              children: [
                                TextSpan(
                                  text: 'Present: ',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '$present\n',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Absent: ',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: '$absent',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: scheme.primary, label: 'Present'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.red.shade700, label: 'Absent'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
