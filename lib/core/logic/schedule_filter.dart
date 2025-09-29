// import 'package:myattendance/core/database/app_database.dart';
// import 'package:intl/intl.dart';
// import 'package:myattendance/core/widgets/get_date_now.dart';

// class ScheduleFilter {
//   Future<List<Schedule>> getCurrentClass() async {
//     final schedules = await AppDatabase.instance.getAllSchedules();
//     return schedules.where((s) {
//       if (s.day != GetDateNow.getDayNow()) return false;
//       List<String> time = s.time.split('-');

//       final DateTime startTime = _parseTime(time[0].trim());
//       final DateTime endTime = _parseTime(time[1].trim());
//       final DateTime currentTime = _parseTime(GetDateNow.getTimeNow());

//       return startTime.isBefore(currentTime) && endTime.isAfter(currentTime);
//     }).toList();
//   }

//   Future<List<Schedule>> getNextClass() async {
//     final schedules = await AppDatabase.instance.getAllSchedules();
//     final today = GetDateNow.getDayNow();

//     final now = _parseTime(GetDateNow.getTimeNow());

//     final upcoming = schedules.where((s) {
//       if (s.day != today) return false;
//       final parts = s.time.split('-');
//       if (parts.length < 2) return false;
//       final start = _parseTime(parts[0].trim());
//       return start.isAfter(now);
//     }).toList();

//     // Sort by start time and return first item as list (to mirror existing API)
//     upcoming.sort((a, b) {
//       final aStart = _parseTime(a.time.split('-').first.trim());
//       final bStart = _parseTime(b.time.split('-').first.trim());
//       return aStart.compareTo(bStart);
//     });

//     if (upcoming.isEmpty) return [];
//     return [upcoming.first];
//   }

//   DateTime _parseTime(String input) {
//     final List<DateFormat> formats = [
//       DateFormat('h:mm a'),
//       DateFormat('hh:mm a'),
//       DateFormat('H:mm'),
//       DateFormat('HH:mm'),
//       DateFormat('h:mm'),
//     ];

//     for (final f in formats) {
//       try {
//         final parsed = f.parse(input);
//         return DateTime(0, 1, 1, parsed.hour, parsed.minute);
//       } catch (_) {}
//     }

//     // Fallback: 00:00
//     return DateTime(0, 1, 1, 0, 0);
//   }
// }
