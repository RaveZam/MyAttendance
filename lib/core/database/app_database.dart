import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subjectCode => text()();
  TextColumn get subjectName => text()();
  TextColumn get term => text()();
  TextColumn get yearLevel => text()();
  TextColumn get section => text()();
  TextColumn get profId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer().customConstraint(
    'NOT NULL REFERENCES subjects(id) ON DELETE CASCADE',
  )();
  TextColumn get day => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get roomNumber => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Schedules, Subjects])
class AppDatabase extends _$AppDatabase {
  AppDatabase._([QueryExecutor? executor])
    : super(executor ?? _openConnection());

  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migrations {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'myattendancedb_reset',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  Future<int> insertSubject(SubjectsCompanion entry) {
    try {
      return into(subjects).insert(entry);
    } catch (e, stack) {
      print("Insert error: $e\n$stack");
      rethrow; // keeps the original error trace
    }
  }

  Future<int> insertSchedule(SchedulesCompanion entry) {
    try {
      return into(schedules).insert(entry);
    } catch (e, stack) {
      print("Schedule insert error: $e\n$stack");
      rethrow;
    }
  }

  Future<void> insertSchedules(List<SchedulesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(schedules, entries);
    });
  }

  Future<List<Subject>> getAllSubjects() => select(subjects).get();
  Future<List<Schedule>> getAllSchedules() => select(schedules).get();

  Future<List<Schedule>> getSchedulesBySubjectId(int subjectId) {
    return (select(
      schedules,
    )..where((tbl) => tbl.subjectId.equals(subjectId))).get();
  }

  Future<void> deleteAllSchedules() => delete(schedules).go();

  Future<void> deleteAllSubjects() => delete(subjects).go();

  Future<void> clearAllData() async {
    await deleteAllSchedules();
    await deleteAllSubjects();
  }
}
