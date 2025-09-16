import 'package:intl/intl.dart';

class GetDateNow {
  DateTime now = DateTime.now();

  static String getTimeNow() {
    final now = DateTime.now();
    return DateFormat('hh:mm a').format(now);
  }

  static String getDateNow() {
    final now = DateTime.now();
    return DateFormat('dd/MM/yyyy').format(now);
  }

  static String getDayNow() {
    final now = DateTime.now();
    return DateFormat('EEEE').format(now);
  }
}
