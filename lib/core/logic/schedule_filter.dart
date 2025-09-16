import 'package:myattendance/core/database/app_database.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/core/widgets/get_date_now.dart';

class ScheduleFilter {
  List<Schedule> getCurrentClass(List<Schedule> schedules) {
    return schedules.where((s) {
      if (s.day != GetDateNow.getDayNow()) return false;
      List<String> time = s.time.split('-');

      DateFormat format = DateFormat("h:mm");
      DateTime startTime = format.parse(time[0].trim());
      DateTime endTime = format.parse(time[1].trim());
      DateTime currentTime = format.parse(GetDateNow.getTimeNow());

      return startTime.isBefore(currentTime) && endTime.isAfter(currentTime);
    }).toList();
  }
}
