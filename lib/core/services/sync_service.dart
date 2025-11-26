import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

/// Represents the sync status between local and server
enum SyncStatus {
  upToDate, // Both are in sync
  serverNewer, // Server has newer changes
  localNewer, // Local has newer changes
  bothNewer, // Both have newer changes (conflict)
  unknown, // Unable to determine
}

/// Sync status result with details
class SyncStatusResult {
  final SyncStatus status;
  final DateTime? localLatest;
  final DateTime? serverLatest;
  final int localUnsyncedCount;
  final String message;

  SyncStatusResult({
    required this.status,
    this.localLatest,
    this.serverLatest,
    required this.localUnsyncedCount,
    required this.message,
  });
}

class SyncService {
  final AppDatabase db;
  final SupabaseClient supabase;
  bool _isSyncing = false;

  SyncService({required this.db, required this.supabase});

  /// Uploads all local unsynced changes to Supabase
  /// This method assumes the caller has already acquired the _isSyncing lock
  Future<void> _performUpload() async {
    debugPrint('🔄 Starting upload...');

    final termsFuture = _syncTable(
      tableName: 'terms',
      getUnsynced: () =>
          (db.select(db.terms)..where((t) => t.synced.equals(false))).get(),
      markSynced: (ids) async {
        await (db.update(db.terms)..where((t) => t.id.isIn(ids))).write(
          TermsCompanion(synced: Value(true)),
        );
      },
      mapRow: (term) => {
        'term': term.term,
        'start_year': term.startYear,
        'end_year': term.endYear,
      },
    );

    final studentsFuture = _syncTable(
      tableName: 'students',
      getUnsynced: () =>
          (db.select(db.students)..where((t) => t.synced.equals(false))).get(),
      markSynced: (ids) async {
        await (db.update(db.students)..where((t) => t.id.isIn(ids))).write(
          StudentsCompanion(synced: const Value(true)),
        );
      },
      mapRow: (s) => {
        'local_id': s.id,
        'first_name': s.firstName,
        'last_name': s.lastName,
        'student_id': s.studentId,
        'created_at': s.createdAt.toIso8601String(),
        'last_modified': s.lastModified.toIso8601String(),
      },
    );

    final subjectsFuture = _syncTable(
      tableName: 'subjects',
      getUnsynced: () =>
          (db.select(db.subjects)..where((t) => t.synced.equals(false))).get(),
      markSynced: (ids) async {
        await (db.update(db.subjects)..where((t) => t.id.isIn(ids))).write(
          SubjectsCompanion(synced: Value(true)),
        );
      },
      mapRow: (s) => {
        'local_id': (s as dynamic).id,
        'subject_code': (s as dynamic).subjectCode,
        'subject_name': (s as dynamic).subjectName,
        'year_level': (s as dynamic).yearLevel,
        'section': (s as dynamic).section,
        // send local refs; we'll resolve to server UUIDs in the sync helper
        'prof_local_id': (s as dynamic).profId,
        'term_local_id': (s as dynamic).termId,
        'created_at': (s as dynamic).createdAt.toIso8601String(),
        'last_modified': (s as dynamic).lastModified.toIso8601String(),
      },
    );

    final schedulesFuture = _syncTable(
      tableName: 'schedules',
      getUnsynced: () =>
          (db.select(db.schedules)..where((t) => t.synced.equals(false))).get(),
      markSynced: (ids) async {
        await (db.update(db.schedules)..where((t) => t.id.isIn(ids))).write(
          SchedulesCompanion(synced: Value(true)),
        );
      },
      mapRow: (s) => {
        'local_id': (s as dynamic).id,
        'local_subject_id': (s as dynamic).subjectId,
        'day': (s as dynamic).day,
        'start_time': (s as dynamic).startTime,
        'end_time': (s as dynamic).endTime,
        'room': (s as dynamic).room,
        'created_at': (s as dynamic).createdAt.toIso8601String(),
        'last_modified': (s as dynamic).lastModified.toIso8601String(),
      },
    );
    final sessionsFuture = _syncTable(
      tableName: 'sessions',
      getUnsynced: () =>
          (db.select(db.sessions)..where((t) => t.synced.equals(false))).get(),
      markSynced: (ids) async {
        await (db.update(db.sessions)..where((t) => t.id.isIn(ids))).write(
          SessionsCompanion(synced: Value(true)),
        );
      },
      mapRow: (s) => {
        'local_id': s.id,
        'local_subject_id': s.subjectId,
        'start_time': s.startTime.toIso8601String(),
        'end_time': s.endTime?.toIso8601String(),
        'status': s.status,
        'created_at': s.createdAt.toIso8601String(),
        'last_modified': s.lastModified.toIso8601String(),
      },
    );

    final attendanceFuture = _syncTable(
      tableName: 'attendance',
      getUnsynced: () => (db.select(
        db.attendance,
      )..where((t) => t.synced.equals(false))).get(),
      markSynced: (ids) async {
        await (db.update(db.attendance)..where((t) => t.id.isIn(ids))).write(
          AttendanceCompanion(synced: Value(true)),
        );
      },
      mapRow: (a) => {
        'local_id': (a as dynamic).id,
        'student_id': (a as dynamic).studentId,
        'local_session_id': (a as dynamic).sessionId,
        'status': (a as dynamic).status,
        'created_at': (a as dynamic).createdAt.toIso8601String(),
        'last_modified': (a as dynamic).lastModified.toIso8601String(),
      },
    );

    final subjectStudentsFuture = _syncTable(
      tableName: 'subject_students',
      getUnsynced: () => (db.select(
        db.subjectStudents,
      )..where((t) => t.synced.equals(false))).get(),
      markSynced: (ids) async {
        await (db.update(db.subjectStudents)..where((t) => t.id.isIn(ids)))
            .write(SubjectStudentsCompanion(synced: Value(true)));
      },
      mapRow: (ss) => {
        'local_id': (ss as dynamic).id,
        'local_student_id': (ss as dynamic).studentId,
        'local_subject_id': (ss as dynamic).subjectId,
        'created_at': (ss as dynamic).createdAt.toIso8601String(),
        'last_modified': (ss as dynamic).lastModified.toIso8601String(),
      },
    );

    // Wait for all sync operations to complete
    await Future.wait([
      termsFuture,
      studentsFuture,
      subjectsFuture,
      schedulesFuture,
      sessionsFuture,
      attendanceFuture,
      subjectStudentsFuture,
    ]);

    debugPrint('✅ Upload complete!');
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _performUpload();
    } catch (e, st) {
      debugPrint('❌ Sync error: $e\n$st');
    } finally {
      _isSyncing = false;
    }
  }

  /// Generic sync helper
  Future<void> _syncTable({
    required String tableName,
    required Future<List<dynamic>> Function() getUnsynced,
    required Future<void> Function(List<int> ids) markSynced,
    required Map<String, dynamic> Function(dynamic row) mapRow,
  }) async {
    final unsynced = await getUnsynced();
    if (unsynced.isEmpty) return;

    // Build payloads, resolving any server-side IDs required (e.g., subject.term_id)
    final List<Map<String, dynamic>> data = [];
    for (final row in unsynced) {
      final payload = Map<String, dynamic>.from(mapRow(row));

      if (tableName == 'subjects') {
        // Resolve term UUID from Supabase by matching term fields from local DB
        final int? localTermId = (row as dynamic).termId as int?;
        String? serverTermId;
        if (localTermId != null) {
          final localTerm = await db.getTermById(localTermId);
          if (localTerm != null) {
            try {
              final termResp = await supabase
                  .from('terms')
                  .select('id')
                  .eq('term', localTerm.term)
                  .eq('start_year', localTerm.startYear)
                  .eq('end_year', localTerm.endYear)
                  .maybeSingle();

              if (termResp != null && termResp.containsKey('id')) {
                serverTermId = termResp['id'] as String?;
              }
            } catch (e) {
              debugPrint(
                'Failed to query remote term for local term $localTermId: $e',
              );
            }
          }
        }

        if (serverTermId != null) {
          payload['term_id'] = serverTermId;
        }

        final profId = supabase.auth.currentUser?.id;
        if (profId != null) payload['prof_id'] = profId;

        payload.remove('term_local_id');
        payload.remove('prof_local_id');
      }

      data.add(payload);
    }

    debugPrint(
      '🚀 Attempting to upload ${data.length} records to "$tableName"...',
    );

    try {
      await supabase.from(tableName).insert(data);

      // If insert succeeds, mark as synced
      final ids = unsynced.map((row) => (row as dynamic).id as int).toList();
      await markSynced(ids);

      debugPrint(
        '✅ Successfully uploaded ${data.length} records to "$tableName".',
      );
    } catch (e) {
      debugPrint('❌ FAILED to upload to "$tableName".');
      debugPrint('⚠️ Error details: $e');
    }
  }

  /// Get the latest last_modified timestamp from local database for a table
  Future<DateTime?> _getLocalLatestModified(String tableName) async {
    try {
      switch (tableName) {
        case 'students':
          final students = await (db.select(
            db.students,
          )..orderBy([(t) => OrderingTerm.desc(t.lastModified)])).get();
          return students.isNotEmpty ? students.first.lastModified : null;
        case 'subjects':
          final subjects = await (db.select(
            db.subjects,
          )..orderBy([(t) => OrderingTerm.desc(t.lastModified)])).get();
          return subjects.isNotEmpty ? subjects.first.lastModified : null;
        case 'schedules':
          final schedules = await (db.select(
            db.schedules,
          )..orderBy([(t) => OrderingTerm.desc(t.lastModified)])).get();
          return schedules.isNotEmpty ? schedules.first.lastModified : null;
        case 'sessions':
          final sessions = await (db.select(
            db.sessions,
          )..orderBy([(t) => OrderingTerm.desc(t.lastModified)])).get();
          return sessions.isNotEmpty ? sessions.first.lastModified : null;
        case 'attendance':
          final attendance = await (db.select(
            db.attendance,
          )..orderBy([(t) => OrderingTerm.desc(t.lastModified)])).get();
          return attendance.isNotEmpty ? attendance.first.lastModified : null;
        case 'subject_students':
          final subjectStudents = await (db.select(
            db.subjectStudents,
          )..orderBy([(t) => OrderingTerm.desc(t.lastModified)])).get();
          return subjectStudents.isNotEmpty
              ? subjectStudents.first.lastModified
              : null;
        default:
          return null;
      }
    } catch (e) {
      debugPrint('Error getting local latest modified for $tableName: $e');
      return null;
    }
  }

  /// Get the latest last_modified timestamp from Supabase for a table
  Future<DateTime?> _getServerLatestModified(String tableName) async {
    try {
      final profId = supabase.auth.currentUser?.id;
      if (profId == null) return null;

      // For tables that are prof-specific, filter by prof_id
      if (tableName == 'subjects') {
        final response = await supabase
            .from(tableName)
            .select('last_modified')
            .eq('prof_id', profId)
            .order('last_modified', ascending: false)
            .limit(1)
            .maybeSingle();
        if (response != null && response['last_modified'] != null) {
          return DateTime.parse(response['last_modified']);
        }
      } else if (tableName == 'schedules') {
        // Get schedules for prof's subjects
        final profSubjects = await supabase
            .from('subjects')
            .select('subject_code')
            .eq('prof_id', profId);
        final profSubjectCodes = profSubjects
            .map<String>((e) => e['subject_code'] as String)
            .toSet();

        if (profSubjectCodes.isEmpty) return null;

        // Get schedules for prof's subjects - need to query differently
        // Since schedules might not have subject_code directly, we'll get all schedules
        // and filter client-side or use a join query
        final response = await supabase
            .from(tableName)
            .select('last_modified')
            .order('last_modified', ascending: false)
            .limit(1)
            .maybeSingle();
        if (response != null && response['last_modified'] != null) {
          return DateTime.parse(response['last_modified']);
        }
      } else {
        // For other tables, get all records
        final response = await supabase
            .from(tableName)
            .select('last_modified')
            .order('last_modified', ascending: false)
            .limit(1)
            .maybeSingle();
        if (response != null && response['last_modified'] != null) {
          return DateTime.parse(response['last_modified']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting server latest modified for $tableName: $e');
      return null;
    }
  }

  /// Get count of unsynced local records
  Future<int> _getUnsyncedCount(String tableName) async {
    try {
      switch (tableName) {
        case 'terms':
          return (await (db.select(
            db.terms,
          )..where((t) => t.synced.equals(false))).get()).length;
        case 'students':
          return (await (db.select(
            db.students,
          )..where((t) => t.synced.equals(false))).get()).length;
        case 'subjects':
          return (await (db.select(
            db.subjects,
          )..where((t) => t.synced.equals(false))).get()).length;
        case 'schedules':
          return (await (db.select(
            db.schedules,
          )..where((t) => t.synced.equals(false))).get()).length;
        case 'sessions':
          return (await (db.select(
            db.sessions,
          )..where((t) => t.synced.equals(false))).get()).length;
        case 'attendance':
          return (await (db.select(
            db.attendance,
          )..where((t) => t.synced.equals(false))).get()).length;
        case 'subject_students':
          return (await (db.select(
            db.subjectStudents,
          )..where((t) => t.synced.equals(false))).get()).length;
        default:
          return 0;
      }
    } catch (e) {
      debugPrint('Error getting unsynced count for $tableName: $e');
      return 0;
    }
  }

  /// Check sync status by comparing local and server timestamps
  Future<SyncStatusResult> checkSyncStatus() async {
    final profId = supabase.auth.currentUser?.id;
    if (profId == null) {
      return SyncStatusResult(
        status: SyncStatus.unknown,
        localUnsyncedCount: 0,
        message: 'No user logged in',
      );
    }

    try {
      // Check all tables that have last_modified
      final tables = [
        'students',
        'subjects',
        'schedules',
        'sessions',
        'attendance',
        'subject_students',
      ];

      DateTime? maxLocalModified;
      DateTime? maxServerModified;
      int totalUnsynced = 0;

      for (final table in tables) {
        final localLatest = await _getLocalLatestModified(table);
        final serverLatest = await _getServerLatestModified(table);
        final unsynced = await _getUnsyncedCount(table);

        totalUnsynced += unsynced;

        if (localLatest != null) {
          maxLocalModified =
              maxLocalModified == null || localLatest.isAfter(maxLocalModified)
              ? localLatest
              : maxLocalModified;
        }

        if (serverLatest != null) {
          maxServerModified =
              maxServerModified == null ||
                  serverLatest.isAfter(maxServerModified)
              ? serverLatest
              : maxServerModified;
        }
      }

      // Determine status
      SyncStatus status;
      String message;

      if (maxLocalModified == null && maxServerModified == null) {
        status = SyncStatus.upToDate;
        message = 'No data to sync';
      } else if (maxLocalModified == null) {
        status = SyncStatus.serverNewer;
        message = 'Server has data, local is empty';
      } else if (maxServerModified == null) {
        status = SyncStatus.localNewer;
        message = 'Local has data, server is empty';
      } else {
        final localHasUnsynced = totalUnsynced > 0;
        final serverIsNewer = maxServerModified.isAfter(maxLocalModified);
        final localIsNewer = maxLocalModified.isAfter(maxServerModified);

        if (localHasUnsynced && serverIsNewer) {
          status = SyncStatus.bothNewer;
          message = 'Both local and server have newer changes';
        } else if (localHasUnsynced) {
          status = SyncStatus.localNewer;
          message = 'Local has unsynced changes';
        } else if (serverIsNewer) {
          status = SyncStatus.serverNewer;
          message = 'Server has newer changes';
        } else if (localIsNewer) {
          status = SyncStatus.localNewer;
          message = 'Local has newer changes';
        } else {
          status = SyncStatus.upToDate;
          message = 'Everything is up to date';
        }
      }

      return SyncStatusResult(
        status: status,
        localLatest: maxLocalModified,
        serverLatest: maxServerModified,
        localUnsyncedCount: totalUnsynced,
        message: message,
      );
    } catch (e, st) {
      debugPrint('Error checking sync status: $e\n$st');
      return SyncStatusResult(
        status: SyncStatus.unknown,
        localUnsyncedCount: 0,
        message: 'Error checking sync status: $e',
      );
    }
  }

  /// Smart sync that handles bidirectional sync based on status
  Future<void> smartSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    debugPrint('🔄 Starting smart sync...');
    try {
      final status = await checkSyncStatus();
      debugPrint('📊 Sync status: ${status.status} - ${status.message}');

      switch (status.status) {
        case SyncStatus.serverNewer:
          debugPrint('⬇️ Downloading changes from server...');
          await loadDataFromSupabase();
          break;

        case SyncStatus.localNewer:
          debugPrint('⬆️ Uploading local changes to server...');
          await _performUpload();
          break;

        case SyncStatus.bothNewer:
          debugPrint(
            '🔄 Both have changes - downloading first, then uploading...',
          );
          // Download first to get latest server state
          await loadDataFromSupabase();
          // Then upload local changes
          await _performUpload();
          break;

        case SyncStatus.upToDate:
          debugPrint('✅ Everything is up to date');
          break;

        case SyncStatus.unknown:
          debugPrint('⚠️ Unable to determine sync status');
          break;
      }

      debugPrint('✅ Smart sync complete!');
    } catch (e, st) {
      debugPrint('❌ Smart sync error: $e\n$st');
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> loadDataFromSupabase() async {
    final profId = supabase.auth.currentUser?.id;
    if (profId == null) {
      debugPrint('⚠️ No logged-in professor found.');
      return;
    }

    debugPrint('⬇️ Loading data from Supabase for prof_id: $profId');

    try {
      // 1️⃣ Load Terms
      final terms = await supabase.from('terms').select();
      for (final term in terms) {
        final termRows =
            await (db.select(db.terms)..where(
                  (t) =>
                      t.term.equals(term['term']) &
                      t.startYear.equals(term['start_year']) &
                      t.endYear.equals(term['end_year']),
                ))
                .get();
        final local = termRows.isEmpty ? null : termRows.first;

        if (local == null) {
          await db
              .into(db.terms)
              .insert(
                TermsCompanion.insert(
                  term: term['term'],
                  startYear: term['start_year'],
                  endYear: term['end_year'],
                  synced: true,
                ),
              );
        }
      }

      // 2️⃣ Load Students
      final students = await supabase.from('students').select();
      for (final s in students) {
        final studentRows = await (db.select(
          db.students,
        )..where((t) => t.studentId.equals(s['student_id']))).get();
        final local = studentRows.isEmpty ? null : studentRows.first;

        if (local == null) {
          await db
              .into(db.students)
              .insert(
                StudentsCompanion.insert(
                  firstName: s['first_name'],
                  lastName: s['last_name'],
                  studentId: s['student_id'],
                  createdAt: Value(DateTime.parse(s['created_at'])),
                  lastModified: Value(DateTime.parse(s['last_modified'])),
                  synced: true,
                ),
              );
        } else {
          final serverModified = DateTime.parse(s['last_modified']);
          if (serverModified.isAfter(local.lastModified)) {
            await (db.update(
              db.students,
            )..where((t) => t.id.equals(local.id))).write(
              StudentsCompanion(
                firstName: Value(s['first_name']),
                lastName: Value(s['last_name']),
                lastModified: Value(serverModified),
                synced: const Value(true),
              ),
            );
          }
        }
      }

      // 3️⃣ Load Subjects for current prof
      final subjects = await supabase
          .from('subjects')
          .select()
          .eq('prof_id', profId);

      for (final s in subjects) {
        final subjectRows = await (db.select(
          db.subjects,
        )..where((t) => t.subjectCode.equals(s['subject_code']))).get();
        final local = subjectRows.isEmpty ? null : subjectRows.first;

        if (local == null) {
          // find termId locally using term_uuid
          final remoteTermId = s['term_id'];
          int? localTermId;
          if (remoteTermId != null) {
            try {
              final termResp = await supabase
                  .from('terms')
                  .select()
                  .eq('id', remoteTermId)
                  .maybeSingle();

              if (termResp != null) {
                final remoteTermName = termResp['term'];
                final remoteStartYear = termResp['start_year'];
                final remoteEndYear = termResp['end_year'];

                final matchingTermRows =
                    await (db.select(db.terms)..where(
                          (t) =>
                              t.term.equals(remoteTermName) &
                              t.startYear.equals(remoteStartYear) &
                              t.endYear.equals(remoteEndYear),
                        ))
                        .get();

                if (matchingTermRows.isNotEmpty) {
                  localTermId = matchingTermRows.first.id;
                } else {
                  // Insert the term locally so we have a mapping
                  final inserted = await db
                      .into(db.terms)
                      .insert(
                        TermsCompanion.insert(
                          term: remoteTermName,
                          startYear: remoteStartYear,
                          endYear: remoteEndYear,
                          synced: true,
                        ),
                      );
                  localTermId = inserted;
                }
              }
            } catch (e) {
              debugPrint('Failed to resolve remote term $remoteTermId: $e');
            }
          }

          if (localTermId == null) {
            debugPrint(
              '⚠️ Skipping subject ${s['subject_code']} — remote term missing or could not be resolved',
            );
            continue;
          }

          await db
              .into(db.subjects)
              .insert(
                SubjectsCompanion.insert(
                  subjectCode: s['subject_code'],
                  subjectName: s['subject_name'],
                  yearLevel: s['year_level'],
                  section: s['section'],
                  profId: s['prof_id'] ?? profId,
                  termId: localTermId,
                  createdAt: Value(DateTime.parse(s['created_at'])),
                  lastModified: Value(DateTime.parse(s['last_modified'])),
                  synced: true,
                ),
              );
        } else {
          final serverModified = DateTime.parse(s['last_modified']);
          if (serverModified.isAfter(local.lastModified)) {
            await (db.update(
              db.subjects,
            )..where((t) => t.id.equals(local.id))).write(
              SubjectsCompanion(
                subjectName: Value(s['subject_name']),
                yearLevel: Value(s['year_level']),
                section: Value(s['section']),
                lastModified: Value(serverModified),
                synced: const Value(true),
              ),
            );
          }
        }
      }

      final schedules = await supabase.from('schedules').select();

      // Fetch current professor's subjects to know which schedules belong to them
      final profSubjects = await supabase
          .from('subjects')
          .select()
          .eq('prof_id', profId);
      final Set<String> profSubjectCodes = profSubjects
          .map<String>((e) => e['subject_code'] as String)
          .toSet();

      for (final s in schedules) {
        final scheduleSubjectCode = s['subject_code'] as String?;
        if (scheduleSubjectCode == null ||
            !profSubjectCodes.contains(scheduleSubjectCode)) {
          continue; // skip schedules that don't belong to this prof
        }

        final scheduleRows =
            await (db.select(db.schedules)..where(
                  (t) =>
                      t.day.equals(s['day']) &
                      t.startTime.equals(s['start_time']),
                ))
                .get();
        final local = scheduleRows.isEmpty ? null : scheduleRows.first;

        if (local == null) {
          await db
              .into(db.schedules)
              .insert(
                SchedulesCompanion.insert(
                  subjectId: s['local_subject_id'] ?? 0,
                  day: s['day'],
                  startTime: s['start_time'],
                  endTime: s['end_time'],
                  room: Value(s['room']),
                  createdAt: Value(DateTime.parse(s['created_at'])),
                  lastModified: Value(DateTime.parse(s['last_modified'])),
                  synced: true,
                ),
              );
        }
      }

      debugPrint('✅ Data loaded successfully for prof_id: $profId');
    } catch (e, st) {
      debugPrint('❌ Error loading data from Supabase: $e\n$st');
    }
  }
}
