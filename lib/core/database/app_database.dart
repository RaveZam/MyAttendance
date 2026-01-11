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
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
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
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
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
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
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
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

class Students extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get studentId => text()();
  TextColumn get supabaseId => text().nullable()();
  BoolColumn get synced => boolean()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
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
  TextColumn get supabaseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

/// Queue of remote deletions that still need to be pushed to Supabase.
/// Each row represents: "Delete this record from <tableName> where the
/// remote identifier matches <supabaseId>."
class DeletionQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Supabase table name, e.g. "students", "subject_offerings",
  /// "schedules", "sessions", "attendance", "subject_students".
  TextColumn get targetTable => text()();

  /// Identifier used when deleting on Supabase.
  /// For most tables this is the remote PK "id".
  /// For "students" we use the remote "auth_id" (taken from local Students.supabaseId).
  TextColumn get supabaseId => text()();

  /// Not currently used in logic, but kept for consistency with other tables.
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
    DeletionQueue,
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // Schema v1 -> v2: introduce DeletionQueue table.
      if (from < 2) {
        await m.createTable(deletionQueue);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'myattendancedb_reset',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  /// Inserts a row into the deletion queue.
  /// [tableName] must be the Supabase table name.
  /// [supabaseId] is the identifier used for the delete filter on Supabase.
  Future<int> enqueueDeletion({
    required String tableName,
    required String supabaseId,
  }) async {
    if (supabaseId.isEmpty) return 0;
    return into(deletionQueue).insert(
      DeletionQueueCompanion.insert(
        targetTable: tableName,
        supabaseId: supabaseId,
      ),
    );
  }

  /// Logs all pending deletion-queue items for debugging.
  Future<void> logDeletionQueue() async {
    final items = await select(deletionQueue).get();

    if (items.isEmpty) {
      print('[AppDatabase] DeletionQueue is empty.');
      return;
    }

    print('[AppDatabase] DeletionQueue (${items.length}):');
    for (final item in items) {
      print(
        ' - id=${item.id} '
        '| tableName=${item.targetTable} '
        '| supabaseId=${item.supabaseId} '
        '| createdAt=${item.createdAt.toIso8601String()}',
      );
    }
  }

  /// Helper to enqueue a deletion only if [supabaseId] is non-null and non-empty.
  Future<void> _enqueueIfSupabaseIdNotNull({
    required String tableName,
    required String? supabaseId,
  }) async {
    if (supabaseId == null || supabaseId.isEmpty) return;
    await enqueueDeletion(tableName: tableName, supabaseId: supabaseId);
  }

  Future<List<Session>> getSessionByID(int sessionId) {
    return (select(sessions)..where((tbl) => tbl.id.equals(sessionId))).get();
  }

  Future<Session?> getSessionById(int sessionId) async {
    return await (select(
      sessions,
    )..where((tbl) => tbl.id.equals(sessionId))).getSingleOrNull();
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

  Future<List<AttendanceData>> getAttendanceBySessionIds(List<int> sessionIds) {
    if (sessionIds.isEmpty) {
      return Future.value([]);
    }

    return (select(
      attendance,
    )..where((tbl) => tbl.sessionId.isIn(sessionIds))).get();
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

  Future<Student?> getStudentByStudentId(String studentId) {
    // Get all students and filter in memory to handle case-insensitive and whitespace
    // This is more reliable than SQL comparison which can be case-sensitive
    return getAllStudents().then((allStudents) {
      final trimmedSearchId = studentId.trim().toLowerCase();
      for (final student in allStudents) {
        if (student.studentId.trim().toLowerCase() == trimmedSearchId) {
          return student;
        }
      }
      return null;
    });
  }

  Future<Student?> getStudentByStudentIdInSubject(
    String studentId,
    int subjectId,
  ) {
    // Get students in the specific subject and filter in memory
    // to handle case-insensitive and whitespace comparison
    return getStudentsInSubject(subjectId).then((subjectStudents) {
      final trimmedSearchId = studentId.trim().toLowerCase();
      for (final student in subjectStudents) {
        if (student.studentId.trim().toLowerCase() == trimmedSearchId) {
          return student;
        }
      }
      return null;
    });
  }

  Future<int> enrollStudent(int subjectId, int studentId) async {
    return into(subjectStudents).insert(
      SubjectStudentsCompanion.insert(
        subjectId: subjectId,
        studentId: studentId,
        // Leave supabaseId null on initial enroll; it will be filled after upload.
        supabaseId: const Value.absent(),
        synced: const Value(false),
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

  Future<void> logAllStudents() async {
    final allStudents = await getAllStudents();

    if (allStudents.isEmpty) {
      print('[AppDatabase] No students found in the local database.');
      return;
    }

    print('[AppDatabase] Students (${allStudents.length}):');
    for (final student in allStudents) {
      final fullName = '${student.firstName} ${student.lastName}'.trim();
      print(
        ' - localId=${student.id} | name=$fullName | studentId=${student.studentId} | supabaseId=${student.supabaseId ?? 'null'} | synced=${student.synced}',
      );
    }
  }

  /// Logs all local subjects and their relationship to Supabase subject_offerings.
  Future<void> logAllSubjectsAndOfferings() async {
    final allSubjects = await getAllSubjects();

    if (allSubjects.isEmpty) {
      print('[AppDatabase] No subjects found in the local database.');
      return;
    }

    print('[AppDatabase] Subjects (${allSubjects.length}):');
    for (final subject in allSubjects) {
      print(
        ' - localId=${subject.id} '
        '| code=${subject.subjectCode} '
        '| name=${subject.subjectName} '
        '| yearLevel=${subject.yearLevel} '
        '| section=${subject.section} '
        '| termId=${subject.termId} '
        '| profId=${subject.profId} '
        '| supabaseOfferingId=${subject.supabaseId ?? 'null'} '
        '| synced=${subject.synced} '
        '| lastModified=${subject.lastModified.toIso8601String()}',
      );
    }
  }

  /// Logs all entries in the subject-students pivot table to help debug enrollments.
  Future<void> logAllSubjectStudents() async {
    final allSubjectStudents = await select(subjectStudents).get();

    if (allSubjectStudents.isEmpty) {
      print('[AppDatabase] No subject_students found in the local database.');
      return;
    }

    print('[AppDatabase] subject_students (${allSubjectStudents.length}):');
    for (final entry in allSubjectStudents) {
      print(
        ' - localId=${entry.id} '
        '| subjectId=${entry.subjectId} '
        '| studentId=${entry.studentId} '
        '| supabaseId=${entry.supabaseId ?? 'null'} '
        '| synced=${entry.synced} '
        '| lastModified=${entry.lastModified.toIso8601String()}',
      );
    }
  }

  /// Logs only the counts for attendance, sessions, and schedules to avoid noisy output.
  Future<void> logAttendanceSessionScheduleCounts() async {
    final attendanceCount = await _countAttendance();
    final sessionCount = await _countSessions();
    final scheduleCount = await _countSchedules();

    print(
      '[AppDatabase] Counts -> attendance=$attendanceCount, sessions=$sessionCount, schedules=$scheduleCount',
    );
  }

  Future<int> _countAttendance() async {
    final countExp = attendance.id.count();
    final result = await (selectOnly(attendance)..addColumns([countExp]))
        .map((row) => row.read(countExp))
        .getSingleOrNull();
    return result ?? 0;
  }

  Future<int> _countSessions() async {
    final countExp = sessions.id.count();
    final result = await (selectOnly(sessions)..addColumns([countExp]))
        .map((row) => row.read(countExp))
        .getSingleOrNull();
    return result ?? 0;
  }

  Future<int> _countSchedules() async {
    final countExp = schedules.id.count();
    final result = await (selectOnly(schedules)..addColumns([countExp]))
        .map((row) => row.read(countExp))
        .getSingleOrNull();
    return result ?? 0;
  }

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
        lastModified: Value(DateTime.now()),
        synced: Value(false), // Mark as unsynced after update
      ),
    );
  }

  /// Deletes a student and all related local data:
  /// - Removes enrollments from `subjectStudents`
  /// - Removes attendance records matching the student's `studentId`
  /// - Deletes the student row itself
  Future<void> deleteStudentWithRelations(int id) async {
    await transaction(() async {
      // Load the student first so we can match attendance by string studentId
      final student = await (select(
        students,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (student != null) {
        // Enqueue remote deletion for the "students" Supabase row.
        // We use auth_id (stored in local Students.supabaseId) as the delete key.
        await _enqueueIfSupabaseIdNotNull(
          tableName: 'students',
          supabaseId: student.supabaseId,
        );

        // Delete attendance records for this student (studentId is stored as text)
        final attendanceRows = await (select(
          attendance,
        )..where((tbl) => tbl.studentId.equals(student.studentId))).get();
        for (final row in attendanceRows) {
          await _enqueueIfSupabaseIdNotNull(
            tableName: 'attendance',
            supabaseId: row.supabaseId,
          );
        }
        await (delete(
          attendance,
        )..where((tbl) => tbl.studentId.equals(student.studentId))).go();
      }

      // Explicitly delete subject-student relationships for this student
      // (in addition to the ON DELETE CASCADE, to be safe)
      final subjectStudentRows = await (select(
        subjectStudents,
      )..where((t) => t.studentId.equals(id))).get();
      for (final row in subjectStudentRows) {
        await _enqueueIfSupabaseIdNotNull(
          tableName: 'subject_students',
          supabaseId: row.supabaseId,
        );
      }
      await (delete(
        subjectStudents,
      )..where((t) => t.studentId.equals(id))).go();

      // Finally, delete the student row itself
      await deleteStudent(id);
    });
  }

  Future<void> deleteStudent(int id) async {
    // Ensure we enqueue a deletion for the student even if this helper is used
    // without the relation-aware variant.
    final student = await (select(
      students,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (student != null) {
      await _enqueueIfSupabaseIdNotNull(
        tableName: 'students',
        supabaseId: student.supabaseId,
      );
    }
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

  /// Deletes a subject and all related data (sessions, attendance, schedules, pivot rows).
  /// This is explicit to avoid relying solely on FK cascade behavior across platforms.
  Future<void> deleteSubject(int id) async {
    await transaction(() async {
      // Collect session IDs for this subject so we can delete attendance tied to them.
      final sessionIdQuery =
          await (selectOnly(sessions)
                ..addColumns([sessions.id])
                ..where(sessions.subjectId.equals(id)))
              .map((row) => row.read(sessions.id)!)
              .get();

      if (sessionIdQuery.isNotEmpty) {
        // Enqueue deletions for related attendance rows.
        final relatedAttendance = await (select(
          attendance,
        )..where((t) => t.sessionId.isIn(sessionIdQuery))).get();
        for (final row in relatedAttendance) {
          await _enqueueIfSupabaseIdNotNull(
            tableName: 'attendance',
            supabaseId: row.supabaseId,
          );
        }
        await (delete(
          attendance,
        )..where((t) => t.sessionId.isIn(sessionIdQuery))).go();
      }

      // Delete sessions for this subject.
      final relatedSessions = await (select(
        sessions,
      )..where((tbl) => tbl.subjectId.equals(id))).get();
      for (final row in relatedSessions) {
        await _enqueueIfSupabaseIdNotNull(
          tableName: 'sessions',
          supabaseId: row.supabaseId,
        );
      }
      await (delete(sessions)..where((tbl) => tbl.subjectId.equals(id))).go();

      // Delete schedules for this subject.
      final relatedSchedules = await (select(
        schedules,
      )..where((tbl) => tbl.subjectId.equals(id))).get();
      for (final row in relatedSchedules) {
        await _enqueueIfSupabaseIdNotNull(
          tableName: 'schedules',
          supabaseId: row.supabaseId,
        );
      }
      await (delete(schedules)..where((tbl) => tbl.subjectId.equals(id))).go();

      // Delete subject-student pivot rows for this subject.
      final relatedSubjectStudents = await (select(
        subjectStudents,
      )..where((tbl) => tbl.subjectId.equals(id))).get();
      for (final row in relatedSubjectStudents) {
        await _enqueueIfSupabaseIdNotNull(
          tableName: 'subject_students',
          supabaseId: row.supabaseId,
        );
      }
      await (delete(
        subjectStudents,
      )..where((tbl) => tbl.subjectId.equals(id))).go();

      // Finally delete the subject itself.
      final subjectRow = await (select(
        subjects,
      )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
      if (subjectRow != null) {
        await _enqueueIfSupabaseIdNotNull(
          tableName: 'subject_offerings',
          supabaseId: subjectRow.supabaseId,
        );
      }
      await (delete(subjects)..where((tbl) => tbl.id.equals(id))).go();
    });
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
        lastModified: Value(DateTime.now()),
        synced: Value(false), // Mark as unsynced after update
      ),
    );
  }

  /// Clears Supabase IDs and marks the subject and all related rows as
  /// unsynced so that they will be uploaded as *new* records on the next sync.
  /// This is used when a subject was deleted in the cloud from another device,
  /// but still exists locally.
  Future<void> resetSubjectGraphForResync(int subjectId) async {
    await transaction(() async {
      final now = DateTime.now();

      // Reset the subject itself.
      await (update(subjects)..where((tbl) => tbl.id.equals(subjectId))).write(
        SubjectsCompanion(
          supabaseId: const Value(null),
          synced: const Value(false),
          lastModified: Value(now),
        ),
      );

      // Reset schedules for this subject.
      await (update(
        schedules,
      )..where((tbl) => tbl.subjectId.equals(subjectId))).write(
        SchedulesCompanion(
          supabaseId: const Value(null),
          synced: const Value(false),
          lastModified: Value(now),
        ),
      );

      // Reset sessions and remember their IDs so we can also reset attendance.
      final subjectSessions = await (select(
        sessions,
      )..where((tbl) => tbl.subjectId.equals(subjectId))).get();
      final sessionIds = subjectSessions.map((s) => s.id).toList();

      await (update(
        sessions,
      )..where((tbl) => tbl.subjectId.equals(subjectId))).write(
        SessionsCompanion(
          supabaseId: const Value(null),
          synced: const Value(false),
          lastModified: Value(now),
        ),
      );

      if (sessionIds.isNotEmpty) {
        await (update(
          attendance,
        )..where((tbl) => tbl.sessionId.isIn(sessionIds))).write(
          AttendanceCompanion(
            supabaseId: const Value(null),
            synced: const Value(false),
            lastModified: Value(now),
          ),
        );
      }

      // Reset subject-student pivot rows.
      await (update(
        subjectStudents,
      )..where((tbl) => tbl.subjectId.equals(subjectId))).write(
        SubjectStudentsCompanion(
          supabaseId: const Value(null),
          synced: const Value(false),
          lastModified: Value(now),
        ),
      );
    });
  }

  Future<void> deleteSchedulesBySubjectId(int subjectId) async {
    final rows = await (select(
      schedules,
    )..where((tbl) => tbl.subjectId.equals(subjectId))).get();
    for (final row in rows) {
      await _enqueueIfSupabaseIdNotNull(
        tableName: 'schedules',
        supabaseId: row.supabaseId,
      );
    }
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
      SessionsCompanion(
        status: Value('ended'),
        endTime: Value(DateTime.now()),
        lastModified: Value(DateTime.now()),
        synced: Value(false), // Mark as unsynced after update
      ),
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

  /// Clears all data from all tables in the database.
  /// This is used when signing out to remove all offline data.
  Future<void> clearAllDatabaseData() async {
    await transaction(() async {
      // Delete all data from all tables
      // Order matters due to foreign key constraints
      await delete(attendance).go();
      await delete(sessions).go();
      await delete(schedules).go();
      await delete(subjectStudents).go();
      await delete(subjects).go();
      await delete(students).go();
      // Note: We intentionally do NOT enqueue deletions for this bulk-clear
      // operation, since it is used for sign-out/local cache reset and should
      // not wipe data from Supabase.
    });
  }

  /// Clears all drift database data including deletion queue and terms.
  /// TEMPORARY: For debugging purposes only.
  Future<void> clearDriftDatabase() async {
    await transaction(() async {
      // Delete all data from all tables
      // Order matters due to foreign key constraints
      await delete(attendance).go();
      await delete(sessions).go();
      await delete(schedules).go();
      await delete(subjectStudents).go();
      await delete(subjects).go();
      await delete(students).go();
      await delete(terms).go();
      await delete(deletionQueue).go();
    });
  }

  Future<void> clearAttendance() => delete(attendance).go();

  Future<void> clearSessions() => delete(sessions).go();

  Future<void> clearAttendanceSession() async {
    await clearAttendance();
    await clearSessions();
  }

  Future<void> deleteSessionById(int id) async {
    // Enqueue deletion for the session itself and its attendance records.
    final sessionRow = await (select(
      sessions,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (sessionRow != null) {
      await _enqueueIfSupabaseIdNotNull(
        tableName: 'sessions',
        supabaseId: sessionRow.supabaseId,
      );

      final relatedAttendance = await (select(
        attendance,
      )..where((t) => t.sessionId.equals(id))).get();
      for (final row in relatedAttendance) {
        await _enqueueIfSupabaseIdNotNull(
          tableName: 'attendance',
          supabaseId: row.supabaseId,
        );
      }

      await (delete(attendance)..where((t) => t.sessionId.equals(id))).go();
    }

    await (delete(sessions)..where((tbl) => tbl.id.equals(id))).go();
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
    bool synced,
    DateTime lastModified,
    DateTime createdAt,
  ) async {
    await (update(schedules)..where((tbl) => tbl.id.equals(scheduleId))).write(
      SchedulesCompanion(
        day: Value(day),
        startTime: Value(startTime),
        endTime: Value(endTime),
        room: Value(room),
        synced: Value(synced),
        lastModified: Value(lastModified),
        createdAt: Value(createdAt),
      ),
    );
  }

  Future<void> deleteSchedule(int scheduleId) async {
    final scheduleRow = await (select(
      schedules,
    )..where((tbl) => tbl.id.equals(scheduleId))).getSingleOrNull();
    if (scheduleRow != null) {
      await _enqueueIfSupabaseIdNotNull(
        tableName: 'schedules',
        supabaseId: scheduleRow.supabaseId,
      );
    }
    await (delete(schedules)..where((tbl) => tbl.id.equals(scheduleId))).go();
  }

  /// Marks all rows in all Drift tables as unsynced (synced = false).
  /// This is used for debugging sync, forcing the next sync to treat everything as dirty.
  Future<void> markAllDataUnsynced() async {
    await transaction(() async {
      await (update(terms)).write(TermsCompanion(synced: const Value(false)));
      await (update(
        students,
      )).write(StudentsCompanion(synced: const Value(false)));
      await (update(
        subjects,
      )).write(SubjectsCompanion(synced: const Value(false)));
      await (update(
        schedules,
      )).write(SchedulesCompanion(synced: const Value(false)));
      await (update(
        sessions,
      )).write(SessionsCompanion(synced: const Value(false)));
      await (update(
        attendance,
      )).write(AttendanceCompanion(synced: const Value(false)));
      await (update(
        subjectStudents,
      )).write(SubjectStudentsCompanion(synced: const Value(false)));
    });
  }

  /// Clears Supabase IDs and marks a student (and their enrollments) as
  /// unsynced so they can be uploaded as a new record on the next sync.
  Future<void> resetStudentGraphForResync(int studentId) async {
    await transaction(() async {
      final now = DateTime.now();

      await (update(students)..where((tbl) => tbl.id.equals(studentId))).write(
        StudentsCompanion(
          supabaseId: const Value(null),
          synced: const Value(false),
          lastModified: Value(now),
        ),
      );

      await (update(
        subjectStudents,
      )..where((tbl) => tbl.studentId.equals(studentId))).write(
        SubjectStudentsCompanion(
          supabaseId: const Value(null),
          synced: const Value(false),
          lastModified: Value(now),
        ),
      );
    });
  }
}
