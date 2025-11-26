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

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
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

      // Determine status based on conditions:
      // 1. Local Newer: If local has unsynced records or newer timestamp
      // 2. Server Newer: If server has newer timestamp
      // 3. All Synced: Timestamps match (or close enough) and no unsynced records

      SyncStatus status;
      String message;

      // If either is null, treat as "empty" for comparison logic
      final localTime =
          maxLocalModified ?? DateTime.fromMillisecondsSinceEpoch(0);
      final serverTime =
          maxServerModified ?? DateTime.fromMillisecondsSinceEpoch(0);

      final localHasUnsynced = totalUnsynced > 0;
      final serverIsNewer = serverTime.isAfter(localTime);
      // Use a small tolerance for "equality" or strict > for newer
      final localIsNewer = localTime.isAfter(serverTime);

      if (localHasUnsynced) {
        // Condition 1: Local has unsynced records
        status = SyncStatus.localNewer;
        message = 'Local changes found ($totalUnsynced records)';
      } else if (serverIsNewer) {
        // Condition 2: Server is newer
        status = SyncStatus.serverNewer;
        message = 'Server has newer updates';
      } else if (localIsNewer) {
        // Technically local is newer but no "unsynced" count from flags?
        // This might happen if we updated a timestamp but didn't set synced=false (bug?)
        // Or if we just created data. Let's assume we should upload if local is newer.
        status = SyncStatus.localNewer;
        message = 'Local version is newer';
      } else {
        // Condition 3: All Synced
        status = SyncStatus.upToDate;
        message = 'All Synced';
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
      final Map<int, int> studentIdMap = {};
      final Map<int, int> subjectIdMap = {};
      final Set<int> profSubjectLocalIds = {};
      final Set<int> sessionLocalIds = {};

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
        final remoteLocalId = s['local_id'] as int?;
        Student? local;

        if (remoteLocalId != null) {
          local = await (db.select(
            db.students,
          )..where((t) => t.id.equals(remoteLocalId))).getSingleOrNull();
        }

        if (local == null) {
          final studentRows = await (db.select(
            db.students,
          )..where((t) => t.studentId.equals(s['student_id']))).get();
          local = studentRows.isEmpty ? null : studentRows.first;
        }

        final serverModified = _parseDateTime(s['last_modified']);
        final serverCreated = _parseDateTime(s['created_at']);

        if (local == null) {
          await db
              .into(db.students)
              .insert(
                StudentsCompanion(
                  id: remoteLocalId != null
                      ? Value(remoteLocalId)
                      : const Value.absent(),
                  firstName: Value(s['first_name'] ?? ''),
                  lastName: Value(s['last_name'] ?? ''),
                  studentId: Value(s['student_id'] ?? ''),
                  createdAt: Value(serverCreated ?? DateTime.now()),
                  lastModified: Value(serverModified ?? DateTime.now()),
                  synced: const Value(true),
                ),
                mode: InsertMode.insertOrReplace,
              );

          if (remoteLocalId != null) {
            studentIdMap[remoteLocalId] = remoteLocalId;
          }
        } else {
          final resolvedId = local.id;
          if (remoteLocalId != null) {
            studentIdMap[remoteLocalId] = resolvedId;
          }

          if (serverModified != null &&
              serverModified.isAfter(local.lastModified)) {
            await (db.update(
              db.students,
            )..where((t) => t.id.equals(resolvedId))).write(
              StudentsCompanion(
                firstName: Value(s['first_name'] ?? local.firstName),
                lastName: Value(s['last_name'] ?? local.lastName),
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
        final remoteLocalId = s['local_id'] as int?;
        Subject? local;

        if (remoteLocalId != null) {
          local = await (db.select(
            db.subjects,
          )..where((t) => t.id.equals(remoteLocalId))).getSingleOrNull();
        }

        if (local == null) {
          final subjectRows = await (db.select(
            db.subjects,
          )..where((t) => t.subjectCode.equals(s['subject_code']))).get();
          local = subjectRows.isEmpty ? null : subjectRows.first;
        }

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

        if (local == null && localTermId == null) {
          debugPrint(
            '⚠️ Skipping subject ${s['subject_code']} — remote term missing or could not be resolved',
          );
          continue;
        }

        final serverModified = _parseDateTime(s['last_modified']);
        final serverCreated = _parseDateTime(s['created_at']);

        if (local == null) {
          await db
              .into(db.subjects)
              .insert(
                SubjectsCompanion(
                  id: remoteLocalId != null
                      ? Value(remoteLocalId)
                      : const Value.absent(),
                  subjectCode: Value(s['subject_code'] ?? ''),
                  subjectName: Value(s['subject_name'] ?? ''),
                  yearLevel: Value(s['year_level'] ?? ''),
                  section: Value(s['section'] ?? ''),
                  profId: Value(s['prof_id'] ?? profId),
                  termId: Value(localTermId ?? 0),
                  createdAt: Value(serverCreated ?? DateTime.now()),
                  lastModified: Value(serverModified ?? DateTime.now()),
                  synced: const Value(true),
                ),
                mode: InsertMode.insertOrReplace,
              );

          final resolvedId = remoteLocalId ?? 0;
          if (resolvedId != 0) {
            subjectIdMap[resolvedId] = resolvedId;
            profSubjectLocalIds.add(resolvedId);
          }
        } else {
          final resolvedId = local.id;
          if (remoteLocalId != null) {
            subjectIdMap[remoteLocalId] = resolvedId;
            profSubjectLocalIds.add(remoteLocalId);
          } else {
            profSubjectLocalIds.add(resolvedId);
          }

          if (serverModified != null &&
              serverModified.isAfter(local.lastModified)) {
            await (db.update(
              db.subjects,
            )..where((t) => t.id.equals(resolvedId))).write(
              SubjectsCompanion(
                subjectName: Value(s['subject_name'] ?? local.subjectName),
                yearLevel: Value(s['year_level'] ?? local.yearLevel),
                section: Value(s['section'] ?? local.section),
                lastModified: Value(serverModified),
                synced: const Value(true),
              ),
            );
          }
        }
      }

      final schedules = await supabase.from('schedules').select();
      for (final sched in schedules) {
        final remoteSubjectLocalId = sched['local_subject_id'] as int?;
        if (remoteSubjectLocalId == null) continue;
        final mappedSubjectId = subjectIdMap[remoteSubjectLocalId];
        if (mappedSubjectId == null &&
            !profSubjectLocalIds.contains(remoteSubjectLocalId)) {
          continue;
        }
        final subjectIdValue = mappedSubjectId ?? remoteSubjectLocalId;

        final localId = sched['local_id'] as int?;
        if (localId == null) continue;

        final remoteLastModified = _parseDateTime(sched['last_modified']);
        final remoteCreatedAt = _parseDateTime(sched['created_at']);

        final localSchedule = await (db.select(
          db.schedules,
        )..where((t) => t.id.equals(localId))).getSingleOrNull();

        if (localSchedule == null) {
          await db
              .into(db.schedules)
              .insert(
                SchedulesCompanion(
                  id: Value(localId),
                  subjectId: Value(subjectIdValue),
                  day: Value(sched['day'] ?? ''),
                  startTime: Value(sched['start_time'] ?? ''),
                  endTime: Value(sched['end_time'] ?? ''),
                  room: sched['room'] != null
                      ? Value(sched['room'])
                      : const Value.absent(),
                  createdAt: Value(remoteCreatedAt ?? DateTime.now()),
                  lastModified: Value(remoteLastModified ?? DateTime.now()),
                  synced: const Value(true),
                ),
                mode: InsertMode.insertOrReplace,
              );
        } else if (remoteLastModified != null &&
            remoteLastModified.isAfter(localSchedule.lastModified)) {
          await (db.update(
            db.schedules,
          )..where((t) => t.id.equals(localId))).write(
            SchedulesCompanion(
              subjectId: Value(subjectIdValue),
              day: Value(sched['day'] ?? localSchedule.day),
              startTime: Value(sched['start_time'] ?? localSchedule.startTime),
              endTime: Value(sched['end_time'] ?? localSchedule.endTime),
              room: sched['room'] != null
                  ? Value(sched['room'])
                  : Value(localSchedule.room),
              lastModified: Value(remoteLastModified),
              synced: const Value(true),
            ),
          );
        }
      }

      final sessions = await supabase.from('sessions').select();
      for (final session in sessions) {
        final remoteSubjectLocalId = session['local_subject_id'] as int?;
        if (remoteSubjectLocalId == null) continue;
        final mappedSubjectId = subjectIdMap[remoteSubjectLocalId];
        if (mappedSubjectId == null &&
            !profSubjectLocalIds.contains(remoteSubjectLocalId)) {
          continue;
        }
        final subjectIdValue = mappedSubjectId ?? remoteSubjectLocalId;

        final localId = session['local_id'] as int?;
        if (localId == null) continue;
        sessionLocalIds.add(localId);

        final remoteLastModified = _parseDateTime(session['last_modified']);
        final remoteCreatedAt = _parseDateTime(session['created_at']);
        final remoteStart =
            _parseDateTime(session['start_time']) ?? DateTime.now();
        final remoteEnd = _parseDateTime(session['end_time']);
        final status = session['status'] as String? ?? 'ongoing';

        final localSession = await (db.select(
          db.sessions,
        )..where((t) => t.id.equals(localId))).getSingleOrNull();

        if (localSession == null) {
          await db
              .into(db.sessions)
              .insert(
                SessionsCompanion(
                  id: Value(localId),
                  subjectId: Value(subjectIdValue),
                  startTime: Value(remoteStart),
                  endTime: remoteEnd != null
                      ? Value(remoteEnd)
                      : const Value.absent(),
                  status: Value(status),
                  createdAt: Value(remoteCreatedAt ?? DateTime.now()),
                  lastModified: Value(remoteLastModified ?? DateTime.now()),
                  synced: const Value(true),
                ),
                mode: InsertMode.insertOrReplace,
              );
        } else if (remoteLastModified != null &&
            remoteLastModified.isAfter(localSession.lastModified)) {
          await (db.update(
            db.sessions,
          )..where((t) => t.id.equals(localId))).write(
            SessionsCompanion(
              subjectId: Value(subjectIdValue),
              startTime: Value(remoteStart),
              endTime: remoteEnd != null
                  ? Value(remoteEnd)
                  : Value(localSession.endTime),
              status: Value(status),
              lastModified: Value(remoteLastModified),
              synced: const Value(true),
            ),
          );
        }
      }

      final attendanceRecords = await supabase.from('attendance').select();
      for (final record in attendanceRecords) {
        final sessionLocalId = record['local_session_id'] as int?;
        if (sessionLocalId == null || !sessionLocalIds.contains(sessionLocalId))
          continue;

        final localId = record['local_id'] as int?;
        if (localId == null) continue;

        final remoteLastModified = _parseDateTime(record['last_modified']);
        final remoteCreatedAt = _parseDateTime(record['created_at']);

        final localAttendance = await (db.select(
          db.attendance,
        )..where((t) => t.id.equals(localId))).getSingleOrNull();

        if (localAttendance == null) {
          await db
              .into(db.attendance)
              .insert(
                AttendanceCompanion(
                  id: Value(localId),
                  studentId: Value(record['student_id'] ?? ''),
                  sessionId: Value(sessionLocalId),
                  status: Value(record['status'] ?? 'present'),
                  createdAt: Value(remoteCreatedAt ?? DateTime.now()),
                  lastModified: Value(remoteLastModified ?? DateTime.now()),
                  synced: const Value(true),
                ),
                mode: InsertMode.insertOrReplace,
              );
        } else if (remoteLastModified != null &&
            remoteLastModified.isAfter(localAttendance.lastModified)) {
          await (db.update(
            db.attendance,
          )..where((t) => t.id.equals(localId))).write(
            AttendanceCompanion(
              studentId: Value(
                record['student_id'] ?? localAttendance.studentId,
              ),
              sessionId: Value(sessionLocalId),
              status: Value(record['status'] ?? localAttendance.status),
              lastModified: Value(remoteLastModified),
              synced: const Value(true),
            ),
          );
        }
      }

      final subjectStudentsRemote = await supabase
          .from('subject_students')
          .select();
      for (final entry in subjectStudentsRemote) {
        final subjectLocalId = entry['local_subject_id'] as int?;
        final studentLocalId = entry['local_student_id'] as int?;
        if (subjectLocalId == null || studentLocalId == null) continue;

        final mappedSubjectId = subjectIdMap[subjectLocalId] ?? subjectLocalId;
        if (!profSubjectLocalIds.contains(subjectLocalId) &&
            subjectIdMap[subjectLocalId] == null)
          continue;

        final mappedStudentId = studentIdMap[studentLocalId] ?? studentLocalId;

        final localId = entry['local_id'] as int?;
        if (localId == null) continue;

        final remoteLastModified = _parseDateTime(entry['last_modified']);
        final remoteCreatedAt = _parseDateTime(entry['created_at']);

        final localSubjectStudent = await (db.select(
          db.subjectStudents,
        )..where((t) => t.id.equals(localId))).getSingleOrNull();

        if (localSubjectStudent == null) {
          await db
              .into(db.subjectStudents)
              .insert(
                SubjectStudentsCompanion(
                  id: Value(localId),
                  subjectId: Value(mappedSubjectId),
                  studentId: Value(mappedStudentId),
                  createdAt: Value(remoteCreatedAt ?? DateTime.now()),
                  lastModified: Value(remoteLastModified ?? DateTime.now()),
                  synced: const Value(true),
                ),
                mode: InsertMode.insertOrReplace,
              );
        } else if (remoteLastModified != null &&
            remoteLastModified.isAfter(localSubjectStudent.lastModified)) {
          await (db.update(
            db.subjectStudents,
          )..where((t) => t.id.equals(localId))).write(
            SubjectStudentsCompanion(
              subjectId: Value(mappedSubjectId),
              studentId: Value(mappedStudentId),
              lastModified: Value(remoteLastModified),
              synced: const Value(true),
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
