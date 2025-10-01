import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
part 'app_database.g.dart';

class Terms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get term => text()();
  TextColumn get startYear => text()();
  TextColumn get endYear => text()();
  BoolColumn get synced => boolean()();
}

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subjectCode => text()();
  TextColumn get subjectName => text()();
  TextColumn get yearLevel => text()();
  TextColumn get section => text()();
  TextColumn get profId => text()();
  BoolColumn get synced => boolean()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer().customConstraint(
    'NOT NULL REFERENCES subjects(id) ON DELETE CASCADE',
  )();
  IntColumn get termId => integer().customConstraint(
    'NOT NULL REFERENCES terms(id) ON DELETE CASCADE',
  )();
  TextColumn get day => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get room => text().nullable()();
  BoolColumn get synced => boolean()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Schedules, Subjects, Terms])
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

  Future<int> deleteSubject(int id) {
    return (delete(subjects)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateSubject(
    int id,
    String subjectCode,
    String subjectName,
    String yearLevel,
    String section,
  ) async {
    await (update(subjects)..where((tbl) => tbl.id.equals(id))).write(
      SubjectsCompanion(
        subjectCode: Value(subjectCode),
        subjectName: Value(subjectName),
        yearLevel: Value(yearLevel),
        section: Value(section),
      ),
    );
  }

  Future<void> deleteSchedulesBySubjectId(int subjectId) async {
    await (delete(
      schedules,
    )..where((tbl) => tbl.subjectId.equals(subjectId))).go();
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

  Future<List<Term>> getTerms() => select(terms).get();

  Future<Term?> getTermById(int id) async {
    return await (select(
      terms,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> ensureTermsExist(AppDatabase db) async {
    final now = DateTime.now();
    final startYear = now.year;
    final endYear = startYear + 1;

    final existing =
        await (db.select(db.terms)..where(
              (t) =>
                  t.startYear.equals(startYear.toString()) &
                  t.endYear.equals(endYear.toString()),
            ))
            .get();

    if (existing.isEmpty) {
      print("Term Not Existing Detected");
      await db
          .into(db.terms)
          .insert(
            TermsCompanion.insert(
              term: '1st Semester',
              startYear: startYear.toString(),
              endYear: endYear.toString(),
              synced: false,
            ),
          );
      await db
          .into(db.terms)
          .insert(
            TermsCompanion.insert(
              term: 'Mid Year',
              startYear: startYear.toString(),
              endYear: endYear.toString(),
              synced: false,
            ),
          );
      await db
          .into(db.terms)
          .insert(
            TermsCompanion.insert(
              term: '2nd Semester',
              startYear: startYear.toString(),
              endYear: endYear.toString(),
              synced: false,
            ),
          );

      print("Created terms for $startYear-$endYear ✅");
    } else {
      print("Terms for $startYear-$endYear already exist ✅");
    }
  }
}
