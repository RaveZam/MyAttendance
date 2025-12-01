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

    // Skip terms sync - terms are auto-created and never edited
    // final termsFuture = _syncTable(...);

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
      tableName: 'subject_offerings',
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
      // termsFuture, // Skipped - terms are auto-created and never edited
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

    // Separate records into inserts and updates
    final List<Map<String, dynamic>> toInsert = [];
    final List<Map<String, dynamic>> toUpdate = [];

    // Build payloads, resolving any server-side IDs required (e.g., subject.term_id)
    for (final row in unsynced) {
      final payload = Map<String, dynamic>.from(mapRow(row));
      final localId = (row as dynamic).id as int;

      // Check if this record has a supabaseId (already synced before = UPDATE)
      String? supabaseId;

      // Special handling for students table - query Supabase by local_id
      if (tableName == 'students') {
        try {
          final existingStudent = await supabase
              .from('students')
              .select('id')
              .eq('local_id', localId)
              .maybeSingle();

          if (existingStudent != null && existingStudent.containsKey('id')) {
            supabaseId = existingStudent['id'] as String?;
          }
        } catch (e) {
          debugPrint('Failed to check if student exists in Supabase: $e');
          // If query fails, treat as insert
          supabaseId = null;
        }
      } else {
        // For other tables, check if they have supabaseId column
        if (tableName == 'subject_offerings') {
          supabaseId = (row as dynamic).supabaseId as String?;
        } else if (tableName == 'schedules') {
          supabaseId = (row as dynamic).supabaseId as String?;
        } else if (tableName == 'sessions') {
          supabaseId = (row as dynamic).supabaseId as String?;
        } else if (tableName == 'attendance') {
          supabaseId = (row as dynamic).supabaseId as String?;
        } else if (tableName == 'subject_students') {
          supabaseId = (row as dynamic).supabaseId as String?;
        }
      }

      if (tableName == 'subject_offerings') {
        // First, try to resolve the subjects record in Supabase (but do NOT create it)
        final subjectCode = payload['subject_code'] as String?;
        final subjectName = payload['subject_name'] as String?;
        String? subjectUuid;

        if (subjectCode != null && subjectName != null) {
          try {
            // Check if subject exists in Supabase
            final subjectResp = await supabase
                .from('subjects')
                .select('id')
                .eq('code', subjectCode)
                .eq('name', subjectName)
                .maybeSingle();

            if (subjectResp != null && subjectResp.containsKey('id')) {
              subjectUuid = subjectResp['id'] as String?;
            }
          } catch (e) {
            debugPrint('Failed to ensure subject exists in Supabase: $e');
          }
        }

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

        // Set the resolved UUIDs
        // If we could not resolve a subject UUID, skip syncing this offering to avoid
        // accidentally creating or attaching to an unknown subject.
        if (subjectUuid == null) {
          debugPrint(
            '⚠️ Skipping subject_offerings sync for local_id=$localId – subject not found in Supabase.',
          );
          continue;
        }
        payload['subject_id'] = subjectUuid;
        if (serverTermId != null) {
          payload['term_id'] = serverTermId;
        }

        final profId = supabase.auth.currentUser?.id;
        if (profId != null) payload['prof_id'] = profId;

        // Remove fields that are not part of subject_offerings
        payload.remove('subject_code');
        payload.remove('subject_name');
        payload.remove('term_local_id');
        payload.remove('prof_local_id');
      }

      if (tableName == 'subject_students') {
        // Resolve local subject ID to Supabase subject_offerings UUID
        final int? localSubjectId = (row as dynamic).subjectId as int?;
        String? subjectOfferingUuid;

        if (localSubjectId != null) {
          try {
            // Get the local subject to find its supabaseId (which is subject_offerings.id)
            final localSubject = await (db.select(
              db.subjects,
            )..where((t) => t.id.equals(localSubjectId))).getSingleOrNull();

            if (localSubject != null && localSubject.supabaseId != null) {
              // The supabaseId in local subjects table is the subject_offerings.id
              subjectOfferingUuid = localSubject.supabaseId;
            } else {
              // If no supabaseId, try to find the subject_offering by local_id
              final profId = supabase.auth.currentUser?.id;
              if (profId != null) {
                final offeringResp = await supabase
                    .from('subject_offerings')
                    .select('id')
                    .eq('local_id', localSubjectId)
                    .eq('prof_id', profId)
                    .maybeSingle();

                if (offeringResp != null && offeringResp.containsKey('id')) {
                  subjectOfferingUuid = offeringResp['id'] as String?;
                }
              }
            }
          } catch (e) {
            debugPrint(
              'Failed to resolve subject_offering UUID for local subject $localSubjectId: $e',
            );
          }
        }

        // Set the resolved UUID (keep local_subject_id as Supabase needs both)
        if (subjectOfferingUuid != null) {
          payload['subject_id'] = subjectOfferingUuid;
        }
        // Keep local_subject_id - Supabase schema requires both subject_id (UUID) and local_subject_id (int4)
      }

      if (tableName == 'sessions') {
        // Resolve local subject ID to Supabase subject_offerings UUID
        final int? localSubjectId = (row as dynamic).subjectId as int?;
        String? subjectOfferingUuid;

        if (localSubjectId != null) {
          try {
            // Get the local subject to find its supabaseId (which is subject_offerings.id)
            final localSubject = await (db.select(
              db.subjects,
            )..where((t) => t.id.equals(localSubjectId))).getSingleOrNull();

            if (localSubject != null && localSubject.supabaseId != null) {
              // The supabaseId in local subjects table is the subject_offerings.id
              subjectOfferingUuid = localSubject.supabaseId;
            } else {
              // If no supabaseId, try to find the subject_offering by local_id
              final profId = supabase.auth.currentUser?.id;
              if (profId != null) {
                final offeringResp = await supabase
                    .from('subject_offerings')
                    .select('id')
                    .eq('local_id', localSubjectId)
                    .eq('prof_id', profId)
                    .maybeSingle();

                if (offeringResp != null && offeringResp.containsKey('id')) {
                  subjectOfferingUuid = offeringResp['id'] as String?;
                }
              }
            }
          } catch (e) {
            debugPrint(
              'Failed to resolve subject_offering UUID for local subject $localSubjectId in sessions: $e',
            );
          }
        }

        // Set the resolved UUID (keep local_subject_id as Supabase needs both)
        if (subjectOfferingUuid != null) {
          payload['subject_id'] = subjectOfferingUuid;
        }
        // Keep local_subject_id - Supabase schema requires both subject_id (UUID) and local_subject_id (int4)
      }

      if (tableName == 'schedules') {
        // Resolve local subject ID to Supabase subject_offerings UUID
        final int? localSubjectId = (row as dynamic).subjectId as int?;
        String? subjectOfferingUuid;

        if (localSubjectId != null) {
          try {
            // Get the local subject to find its supabaseId (which is subject_offerings.id)
            final localSubject = await (db.select(
              db.subjects,
            )..where((t) => t.id.equals(localSubjectId))).getSingleOrNull();

            if (localSubject != null && localSubject.supabaseId != null) {
              // The supabaseId in local subjects table is the subject_offerings.id
              subjectOfferingUuid = localSubject.supabaseId;
            } else {
              // If no supabaseId, try to find the subject_offering by local_id
              final profId = supabase.auth.currentUser?.id;
              if (profId != null) {
                final offeringResp = await supabase
                    .from('subject_offerings')
                    .select('id')
                    .eq('local_id', localSubjectId)
                    .eq('prof_id', profId)
                    .maybeSingle();

                if (offeringResp != null && offeringResp.containsKey('id')) {
                  subjectOfferingUuid = offeringResp['id'] as String?;
                }
              }
            }
          } catch (e) {
            debugPrint(
              'Failed to resolve subject_offering UUID for local subject $localSubjectId in schedules: $e',
            );
          }
        }

        // Set the resolved UUID (keep local_subject_id as Supabase needs both)
        if (subjectOfferingUuid != null) {
          payload['subject_id'] = subjectOfferingUuid;
        }
        // Keep local_subject_id - Supabase schema requires both subject_id (UUID) and local_subject_id (int4)
      }

      if (tableName == 'attendance') {
        // Resolve session_id (UUID) from local session's supabaseId
        final int? localSessionId = (row as dynamic).sessionId as int?;
        String? sessionUuid;

        if (localSessionId != null) {
          try {
            // Get the local session to find its supabaseId (which is sessions.id UUID)
            final localSession = await (db.select(
              db.sessions,
            )..where((t) => t.id.equals(localSessionId))).getSingleOrNull();

            if (localSession != null && localSession.supabaseId != null) {
              // The supabaseId in local sessions table is the sessions.id UUID
              sessionUuid = localSession.supabaseId;
            } else if (localSession != null) {
              // If no supabaseId, try to find the session by local_id
              final profId = supabase.auth.currentUser?.id;
              if (profId != null) {
                final sessionResp = await supabase
                    .from('sessions')
                    .select('id')
                    .eq('local_id', localSessionId)
                    .maybeSingle();

                if (sessionResp != null && sessionResp.containsKey('id')) {
                  sessionUuid = sessionResp['id'] as String?;
                }
              }
            }
          } catch (e) {
            debugPrint(
              'Failed to resolve session UUID for attendance session $localSessionId: $e',
            );
          }
        }

        // Set the resolved UUID (keep local_session_id as Supabase needs both)
        if (sessionUuid != null) {
          payload['session_id'] = sessionUuid;
        }
        // Keep local_session_id - Supabase schema requires both session_id (UUID) and local_session_id (int4)
      }

      // Separate into inserts and updates based on supabaseId
      if (supabaseId != null && supabaseId.isNotEmpty) {
        // This is an UPDATE - add the supabaseId to identify the record
        payload['id'] = supabaseId;
        toUpdate.add(payload);
      } else {
        // This is an INSERT
        toInsert.add(payload);
      }
    }

    debugPrint(
      '🚀 Syncing "$tableName": ${toInsert.length} inserts, ${toUpdate.length} updates',
    );

    try {
      // Handle INSERTs (new records)
      if (toInsert.isNotEmpty) {
        final insertResponse = await supabase
            .from(tableName)
            .insert(toInsert)
            .select('id, local_id');

        // Mark as synced and store UUIDs for new records
        final newIds = toInsert.map((p) => p['local_id'] as int).toList();
        await markSynced(newIds);

        // Store UUIDs in local database
        for (final item in insertResponse) {
          final localId = item['local_id'] as int?;
          final uuid = item['id'] as String?;

          if (localId != null && uuid != null) {
            // Note: Students table doesn't have supabaseId column,
            // so we don't store it. We'll query by local_id on next sync.
            if (tableName == 'subject_offerings') {
              await (db.update(db.subjects)..where((t) => t.id.equals(localId)))
                  .write(SubjectsCompanion(supabaseId: Value(uuid)));
            } else if (tableName == 'sessions') {
              await (db.update(db.sessions)..where((t) => t.id.equals(localId)))
                  .write(SessionsCompanion(supabaseId: Value(uuid)));
            } else if (tableName == 'attendance') {
              await (db.update(db.attendance)
                    ..where((t) => t.id.equals(localId)))
                  .write(AttendanceCompanion(supabaseId: Value(uuid)));
            } else if (tableName == 'schedules') {
              await (db.update(db.schedules)
                    ..where((t) => t.id.equals(localId)))
                  .write(SchedulesCompanion(supabaseId: Value(uuid)));
            } else if (tableName == 'subject_students') {
              await (db.update(db.subjectStudents)
                    ..where((t) => t.id.equals(localId)))
                  .write(SubjectStudentsCompanion(supabaseId: Value(uuid)));
            }
            // Students table: No need to store UUID since we query by local_id
          }
        }
      }

      // Handle UPDATEs (existing records that were modified)
      if (toUpdate.isNotEmpty) {
        for (final payload in toUpdate) {
          final supabaseId = payload['id'] as String;
          final localId = payload['local_id'] as int;

          // Remove 'id' from payload for update (Supabase uses it to identify)
          final updatePayload = Map<String, dynamic>.from(payload);
          updatePayload.remove('id');

          await supabase
              .from(tableName)
              .update(updatePayload)
              .eq('id', supabaseId);

          // Mark this local record as synced again
          final ids = [localId];
          await markSynced(ids);
        }
      }

      debugPrint(
        '✅ Successfully synced "$tableName": ${toInsert.length} inserts, ${toUpdate.length} updates',
      );
    } catch (e) {
      debugPrint('❌ FAILED to sync "$tableName".');
      debugPrint('⚠️ Error details: $e');
      rethrow;
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
        // Check subject_offerings instead
        final response = await supabase
            .from('subject_offerings')
            .select('last_modified')
            .eq('prof_id', profId)
            .order('last_modified', ascending: false)
            .limit(1)
            .maybeSingle();
        if (response != null && response['last_modified'] != null) {
          return DateTime.parse(response['last_modified']);
        }
      } else if (tableName == 'schedules') {
        // Get schedules for prof's subject offerings - query all schedules
        // (schedules are filtered by subject_offerings relationship)
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

      // 3️⃣ Load Subject Offerings for current prof (join with subjects table)
      final subjectOfferingsResponse = await supabase
          .from('subject_offerings')
          .select('*, subjects(code, name)')
          .eq('prof_id', profId);

      final subjectOfferings = subjectOfferingsResponse as List;

      for (final so in subjectOfferings) {
        final remoteLocalId = so['local_id'] as int?;
        final supabaseUuid = so['id'] as String?;
        final subjectData = so['subjects'] as Map<String, dynamic>?;
        final subjectCode = subjectData?['code'] as String?;
        final subjectName = subjectData?['name'] as String?;

        Subject? local;

        // 1️⃣ Top priority: match by local.supabaseId == remote subject_offerings.id
        if (supabaseUuid != null) {
          local = await (db.select(
            db.subjects,
          )..where((t) => t.supabaseId.equals(supabaseUuid))).getSingleOrNull();
        }

        // 2️⃣ Fallback: match by stored local_id if no supabase match
        if (local == null && remoteLocalId != null) {
          local = await (db.select(
            db.subjects,
          )..where((t) => t.id.equals(remoteLocalId))).getSingleOrNull();
        }

        // find termId locally using term_uuid
        final remoteTermId = so['term_id'];
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

        if (local == null &&
            (localTermId == null ||
                subjectCode == null ||
                subjectName == null)) {
          debugPrint('⚠️ Skipping subject offering — missing required data');
          continue;
        }

        final serverModified = _parseDateTime(so['last_modified']);
        final serverCreated = _parseDateTime(so['created_at']);

        if (local == null) {
          final insertedId = await db
              .into(db.subjects)
              .insert(
                SubjectsCompanion(
                  id: remoteLocalId != null
                      ? Value(remoteLocalId)
                      : const Value.absent(),
                  subjectCode: Value(subjectCode ?? ''),
                  subjectName: Value(subjectName ?? ''),
                  yearLevel: Value(so['year_level'] ?? ''),
                  section: Value(so['section'] ?? ''),
                  profId: Value(so['prof_id'] ?? profId),
                  termId: Value(localTermId ?? 0),
                  supabaseId: supabaseUuid != null
                      ? Value(supabaseUuid)
                      : const Value.absent(),
                  createdAt: Value(serverCreated ?? DateTime.now()),
                  lastModified: Value(serverModified ?? DateTime.now()),
                  synced: const Value(true),
                ),
                mode: InsertMode.insertOrReplace,
              );

          final resolvedId = remoteLocalId ?? insertedId;
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
                subjectName: Value(subjectName ?? local.subjectName),
                yearLevel: Value(so['year_level'] ?? local.yearLevel),
                section: Value(so['section'] ?? local.section),
                supabaseId: supabaseUuid != null
                    ? Value(supabaseUuid)
                    : Value(local.supabaseId),
                lastModified: Value(serverModified),
                synced: const Value(true),
              ),
            );
          } else if (supabaseUuid != null && local.supabaseId != supabaseUuid) {
            // Update UUID even if not newer
            await (db.update(db.subjects)
                  ..where((t) => t.id.equals(resolvedId)))
                .write(SubjectsCompanion(supabaseId: Value(supabaseUuid)));
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

        final supabaseUuid = sched['id'] as String?;
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
                  supabaseId: supabaseUuid != null
                      ? Value(supabaseUuid)
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
              supabaseId: supabaseUuid != null
                  ? Value(supabaseUuid)
                  : Value(localSchedule.supabaseId),
              lastModified: Value(remoteLastModified),
              synced: const Value(true),
            ),
          );
        } else if (supabaseUuid != null &&
            localSchedule.supabaseId != supabaseUuid) {
          // Update UUID even if not newer
          await (db.update(db.schedules)..where((t) => t.id.equals(localId)))
              .write(SchedulesCompanion(supabaseId: Value(supabaseUuid)));
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

        final supabaseUuid = session['id'] as String?;
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
                  supabaseId: supabaseUuid != null
                      ? Value(supabaseUuid)
                      : const Value.absent(),
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
              supabaseId: supabaseUuid != null
                  ? Value(supabaseUuid)
                  : Value(localSession.supabaseId),
              lastModified: Value(remoteLastModified),
              synced: const Value(true),
            ),
          );
        } else if (supabaseUuid != null &&
            localSession.supabaseId != supabaseUuid) {
          // Update UUID even if not newer
          await (db.update(db.sessions)..where((t) => t.id.equals(localId)))
              .write(SessionsCompanion(supabaseId: Value(supabaseUuid)));
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

        final supabaseUuid = record['id'] as String?;
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
                  supabaseId: supabaseUuid != null
                      ? Value(supabaseUuid)
                      : const Value.absent(),
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
              supabaseId: supabaseUuid != null
                  ? Value(supabaseUuid)
                  : Value(localAttendance.supabaseId),
              lastModified: Value(remoteLastModified),
              synced: const Value(true),
            ),
          );
        } else if (supabaseUuid != null &&
            localAttendance.supabaseId != supabaseUuid) {
          // Update UUID even if not newer
          await (db.update(db.attendance)..where((t) => t.id.equals(localId)))
              .write(AttendanceCompanion(supabaseId: Value(supabaseUuid)));
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

        final supabaseUuid = entry['id'] as String?;
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
                  supabaseId: supabaseUuid != null
                      ? Value(supabaseUuid)
                      : const Value.absent(),
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
              supabaseId: supabaseUuid != null
                  ? Value(supabaseUuid)
                  : Value(localSubjectStudent.supabaseId),
              lastModified: Value(remoteLastModified),
              synced: const Value(true),
            ),
          );
        } else if (supabaseUuid != null &&
            localSubjectStudent.supabaseId != supabaseUuid) {
          // Update UUID even if not newer
          await (db.update(db.subjectStudents)
                ..where((t) => t.id.equals(localId)))
              .write(SubjectStudentsCompanion(supabaseId: Value(supabaseUuid)));
        }
      }

      debugPrint('✅ Data loaded successfully for prof_id: $profId');
    } catch (e, st) {
      debugPrint('❌ Error loading data from Supabase: $e\n$st');
    }
  }
}
