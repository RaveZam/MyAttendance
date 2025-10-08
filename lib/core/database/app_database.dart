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

class Attendance extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get studentId => text()();
  IntColumn get sessionId => integer().customConstraint(
    'NOT NULL REFERENCES sessions(id) ON DELETE CASCADE',
  )();
  TextColumn get status => text()();
  BoolColumn get synced => boolean()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get subjectId => integer().customConstraint(
    'NOT NULL REFERENCES subjects(id) ON DELETE CASCADE',
  )();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get status => text()();
  BoolColumn get synced => boolean()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get subjectCode => text()();
  TextColumn get subjectName => text()();
  TextColumn get yearLevel => text()();
  TextColumn get section => text()();
  TextColumn get profId => text()();
  IntColumn get termId => integer().customConstraint(
    'NOT NULL REFERENCES terms(id) ON DELETE CASCADE',
  )();
  BoolColumn get synced => boolean()();
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
  TextColumn get room => text().nullable()();
  BoolColumn get synced => boolean()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get studentId => text()();
  BoolColumn get synced => boolean()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SubjectStudents extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get studentId => integer().customConstraint(
    'NOT NULL REFERENCES students(id) ON DELETE CASCADE',
  )();

  IntColumn get subjectId => integer().customConstraint(
    'NOT NULL REFERENCES subjects(id) ON DELETE CASCADE',
  )();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(
  tables: [
    Schedules,
    Subjects,
    Terms,
    Students,
    SubjectStudents,
    Attendance,
    Sessions,
  ],
)
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

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'myattendancedb_reset',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  Future<List<Session>> getSessionByID(int sessionId) {
    return (select(sessions)..where((tbl) => tbl.id.equals(sessionId))).get();
  }

  /// Returns all sessions for a given subject id.
  Future<List<Session>> getSessionsBySubjectId(int subjectId) {
    return (select(
      sessions,
    )..where((tbl) => tbl.subjectId.equals(subjectId))).get();
  }

  Future<List<AttendanceData>> getAttendanceBySessionID(int sessionID) {
    return (select(
      attendance,
    )..where((tbl) => tbl.sessionId.equals(sessionID))).get();
  }

  Future<int> insertAttendance(AttendanceCompanion entry) {
    try {
      return into(attendance).insert(entry);
    } catch (e, stack) {
      print("Insert error: $e\n$stack");
      rethrow;
    }
  }

  Future<int> insertSession(SessionsCompanion entry) {
    try {
      return into(sessions).insert(entry);
    } catch (e, stack) {
      print("Insert error: $e\n$stack");
      rethrow;
    }
  }

  Future<int> insertStudent(StudentsCompanion entry) {
    try {
      return into(students).insert(entry);
    } catch (e, stack) {
      print("Insert error: $e\n$stack");
      rethrow;
    }
  }

  Future<int> enrollStudent(int subjectId, int studentId) {
    return into(subjectStudents).insert(
      SubjectStudentsCompanion.insert(
        subjectId: subjectId,
        studentId: studentId,
      ),
      mode: InsertMode.insertOrIgnore, // avoids duplicates
    );
  }

  Future<List<Student>> getStudentsInSubject(int subjectId) {
    final query = select(students).join([
      innerJoin(
        subjectStudents,
        subjectStudents.studentId.equalsExp(students.id),
      ),
    ])..where(subjectStudents.subjectId.equals(subjectId));
    return query.map((row) => row.readTable(students)).get();
  }

  Future<List<Student>> getAllStudents() => select(students).get();

  Future<void> updateStudent(
    int id,
    String firstName,
    String lastName,
    String studentId,
  ) async {
    await (update(students)..where((tbl) => tbl.id.equals(id))).write(
      StudentsCompanion(
        firstName: Value(firstName),
        lastName: Value(lastName),
        studentId: Value(studentId),
      ),
    );
  }

  Future<void> deleteStudent(int id) async {
    await (delete(students)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> insertSubject(Insertable<Subject> entry) {
    try {
      return into(subjects).insert(entry);
    } catch (e, stack) {
      print("Insert error: $e\n$stack");
      rethrow;
    }
  }

  Future<int> deleteSubject(int id) {
    return (delete(subjects)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> updateSubject(
    int id,
    String subjectCode,
    String subjectName,
    int termId,
    String yearLevel,
    String section,
  ) async {
    await (update(subjects)..where((tbl) => tbl.id.equals(id))).write(
      SubjectsCompanion(
        subjectCode: Value(subjectCode),
        subjectName: Value(subjectName),
        yearLevel: Value(yearLevel),
        section: Value(section),
        termId: Value(termId),
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

  Future<void> finishSession(int sessionID) async {
    await (update(sessions)..where((tbl) => tbl.id.equals(sessionID))).write(
      SessionsCompanion(status: Value('ended'), endTime: Value(DateTime.now())),
    );
  }

  Future<List<Session>> checkForOngoingSession(int subjectID) {
    return (select(sessions)..where(
          (tbl) =>
              tbl.subjectId.equals(subjectID) & tbl.status.equals('ongoing'),
        ))
        .get();
  }

  Future<void> insertSchedules(List<SchedulesCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(schedules, entries);
    });
  }

  Future<List<Subject>> getAllSubjects() => select(subjects).get();

  Future<List<Subject>> getSubjectByID(int id) {
    return (select(subjects)..where((tbl) => tbl.id.equals(id))).get();
  }

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

  Future<void> clearAttendance() => delete(attendance).go();

  Future<void> clearSessions() => delete(sessions).go();

  Future<void> clearAttendanceSession() async {
    await clearAttendance();
    await clearSessions();
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

  Future<void> updateSchedule(
    int scheduleId,
    String day,
    String startTime,
    String endTime,
    String room,
  ) async {
    await (update(schedules)..where((tbl) => tbl.id.equals(scheduleId))).write(
      SchedulesCompanion(
        day: Value(day),
        startTime: Value(startTime),
        endTime: Value(endTime),
        room: Value(room),
      ),
    );
  }

  Future<void> deleteSchedule(int scheduleId) async {
    await (delete(schedules)..where((tbl) => tbl.id.equals(scheduleId))).go();
  }
}
