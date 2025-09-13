import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subject => text()();
  TextColumn get day => text()();
  TextColumn get time => text()();
  TextColumn get room => text()();
}

@DriftDatabase(tables: [Schedules])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'myattendancedb',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  Future<int> insertSchedule(SchedulesCompanion entry) =>
      into(schedules).insert(entry);

  Future<void> insertSchedules(List<SchedulesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(schedules, entries);
    });
  }

  Future<List<Schedule>> getAllSchedules() => select(schedules).get();
}
