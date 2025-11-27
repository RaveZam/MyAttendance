import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';

class AddSubjectPage extends StatefulWidget {
  final Map<String, dynamic>? existingSubject;
  final List<Map<String, dynamic>>? existingSchedules;

  const AddSubjectPage({
    super.key,
    this.existingSubject,
    this.existingSchedules,
  });

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  final db = AppDatabase.instance;
  final _formKey = GlobalKey<FormBuilderState>();
  final List<Map<String, dynamic>> _schedules = [
    {'day': '', 'startTime': '', 'endTime': ''},
  ];

  List<Term> _terms = [];
  List<Map<String, dynamic>> _availableSubjects = [];
  Map<String, dynamic>? _selectedSubject;
  bool _isLoadingSubjects = false;
  bool _showAvailableSubjects = false;
  final List<String> _gradeLevels = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();
    loadTerms();
    loadAvailableSubjects();
    if (widget.existingSubject != null) {
      _populateFormWithExistingData();
    }
  }

  Future<void> loadAvailableSubjects() async {
    setState(() {
      _isLoadingSubjects = true;
    });
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('subjects')
          .select('code, name, id')
          .order('code');

      setState(() {
        _availableSubjects = List<Map<String, dynamic>>.from(response);
        _isLoadingSubjects = false;
      });
    } catch (e) {
      debugPrint('Error loading available subjects: $e');
      setState(() {
        _isLoadingSubjects = false;
      });
    }
  }

  void _selectSubject(Map<String, dynamic> subject) {
    setState(() {
      _selectedSubject = subject;
      // Pre-fill the form with selected subject
      if (_formKey.currentState != null) {
        _formKey.currentState!.patchValue({
          'subjectCode': subject['code'],
          'subjectName': subject['name'],
        });
      }
    });
  }

  void _clearSelectedSubject() {
    setState(() {
      _selectedSubject = null;
      if (_formKey.currentState != null) {
        _formKey.currentState!.patchValue({
          'subjectCode': null,
          'subjectName': null,
        });
      }
      _showAvailableSubjects = false;
    });
  }

  Future<bool> _checkSubjectExists(String code) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('subjects')
          .select('id')
          .eq('code', code)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking subject existence: $e');
      return false;
    }
  }

  void _populateFormWithExistingData() {
    if (widget.existingSubject != null) {
      // Populate schedules
      _schedules.clear();
      if (widget.existingSchedules != null &&
          widget.existingSchedules!.isNotEmpty) {
        _schedules.addAll(widget.existingSchedules!);
      } else {
        _schedules.add({'day': '', 'startTime': '', 'endTime': '', 'room': ''});
      }

      setState(() {});

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_formKey.currentState != null) {
          Map<String, dynamic> formData = {
            'subjectName': widget.existingSubject!['subjectName'],
            'subjectCode': widget.existingSubject!['subjectCode'],
            'yearLevel': widget.existingSubject!['yearLevel'],
            'section': widget.existingSubject!['section'],
          };

          for (int i = 0; i < _schedules.length; i++) {
            final schedule = _schedules[i];
            if (schedule['startTime'] != null &&
                schedule['startTime'].isNotEmpty) {
              try {
                final timeParts = schedule['startTime'].split(':');
                final startTime = DateTime(
                  2023,
                  1,
                  1,
                  int.parse(timeParts[0]),
                  int.parse(timeParts[1]),
                );
                formData['startTime_$i'] = startTime;
              } catch (e) {
                debugPrint('Error parsing start time: $e');
              }
            }

            if (schedule['endTime'] != null && schedule['endTime'].isNotEmpty) {
              try {
                final timeParts = schedule['endTime'].split(':');
                final endTime = DateTime(
                  2023,
                  1,
                  1,
                  int.parse(timeParts[0]),
                  int.parse(timeParts[1]),
                );
                formData['endTime_$i'] = endTime;
              } catch (e) {
                debugPrint('Error parsing end time: $e');
              }
            }

            if (schedule['room'] != null) {
              formData['room_$i'] = schedule['room'];
            }
          }

          _formKey.currentState!.patchValue(formData);
        }
      });
    }
  }

  Future<void> loadTerms() async {
    // Ensure default terms exist in the database (creates terms if missing)
    await db.ensureTermsExist(db);
    final terms = await db.getTerms();
    setState(() {
      _terms = terms;
    });

    if (widget.existingSubject != null && _terms.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_formKey.currentState != null) {
          _formKey.currentState!.patchValue({'term': _terms.first});
        }
      });
    }
  }

  void createSubject() async {
    final isEditing = widget.existingSubject != null;
    if (_formKey.currentState!.saveAndValidate()) {
      final subject = _formKey.currentState!.value;
      final profId = Supabase.instance.client.auth.currentUser?.id;
      if (profId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to determine the current professor.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      debugPrint("Subject: ${subject.toString()}");

      List<Map<String, dynamic>> scheduleObjects = [];
      for (int i = 0; i < _schedules.length; i++) {
        if (_schedules[i]['day'].isNotEmpty) {
          scheduleObjects.add({
            'day': _schedules[i]['day'],
            'startTime': _schedules[i]['startTime'],
            'endTime': _schedules[i]['endTime'],
            'room': _schedules[i]['room'] ?? '',
            'synced': false,
            'createdAt': DateTime.now(),
            'lastModified': DateTime.now(),
          });
        }
      }

      try {
        if (isEditing) {
          final subjectId = widget.existingSubject!['id'];

          // Update subject
          await db.updateSubject(
            subjectId,
            subject['subjectCode'],
            subject['subjectName'],
            subject['term'].id,
            subject['yearLevel'],
            subject['section'],
          );

          // Get existing schedules to compare
          final existingSchedules = await db.getSchedulesBySubjectId(subjectId);

          // Update or add schedules instead of deleting all
          for (int i = 0; i < scheduleObjects.length; i++) {
            final schedule = scheduleObjects[i];
            if (schedule['day'].isNotEmpty) {
              if (i < existingSchedules.length) {
                // Update existing schedule
                await db.updateSchedule(
                  existingSchedules[i].id,
                  schedule['day'],
                  schedule['startTime'],
                  schedule['endTime'],
                  schedule['room'],
                  schedule['synced'],
                  schedule['lastModified'],
                  schedule['createdAt'],
                );
              } else {
                // Add new schedule
                await db.insertSchedule(
                  SchedulesCompanion(
                    subjectId: drift.Value(subjectId),
                    day: drift.Value(schedule['day']),
                    startTime: drift.Value(schedule['startTime']),
                    endTime: drift.Value(schedule['endTime']),
                    room: drift.Value(schedule['room']),
                    synced: drift.Value(false),
                    lastModified: drift.Value(DateTime.now()),
                    createdAt: drift.Value(DateTime.now()),
                  ),
                );
              }
            }
          }

          // Remove extra schedules if any
          if (scheduleObjects.length < existingSchedules.length) {
            for (
              int i = scheduleObjects.length;
              i < existingSchedules.length;
              i++
            ) {
              await db.deleteSchedule(existingSchedules[i].id);
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject and schedules updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Use selected subject or create new one
          final String subjectCode;
          final String subjectName;
          final String? selectedSubjectId;

          if (_selectedSubject != null) {
            // Use selected subject from Supabase
            subjectCode = _selectedSubject!['code'] as String;
            subjectName = _selectedSubject!['name'] as String;
            selectedSubjectId = _selectedSubject!['id'] as String;
          } else {
            // Use manually entered subject
            subjectCode = subject['subjectCode'] as String;
            subjectName = subject['subjectName'] as String;
            selectedSubjectId = null;
          }

          final subjectCompanion = SubjectsCompanion(
            subjectCode: drift.Value(subjectCode),
            subjectName: drift.Value(subjectName),
            termId: drift.Value(subject['term'].id),
            yearLevel: drift.Value(subject['yearLevel']),
            section: drift.Value(subject['section']),
            profId: drift.Value(profId),
            synced: drift.Value(false),
            createdAt: drift.Value(DateTime.now()),
            lastModified: drift.Value(DateTime.now()),
          );

          final subjectId = await db.insertSubject(subjectCompanion);

          if (scheduleObjects.isNotEmpty) {
            final scheduleCompanions = scheduleObjects.map((schedule) {
              return SchedulesCompanion(
                subjectId: drift.Value(subjectId),
                day: drift.Value(schedule['day']),
                startTime: drift.Value(schedule['startTime']),
                endTime: drift.Value(schedule['endTime']),
                room: drift.Value(schedule['room']),
                synced: drift.Value(false),
                createdAt: drift.Value(DateTime.now()),
                lastModified: drift.Value(DateTime.now()),
              );
            }).toList();

            await db.insertSchedules(scheduleCompanions);
          }

          final insertedSchedules = await db.getSchedulesBySubjectId(subjectId);
          await _syncNewSubjectToSupabase(
            localSubjectId: subjectId,
            code: subjectCode,
            name: subjectName,
            yearLevel: subject['yearLevel'],
            section: subject['section'],
            term: subject['term'] as Term,
            profId: profId,
            schedules: insertedSchedules,
            existingSubjectId: selectedSubjectId,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject and schedules created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        debugPrint('Subject: ${subject.toString()}');
        debugPrint('Schedules: ${scheduleObjects.toString()}');

        Navigator.pop(context, true);
      } catch (e) {
        debugPrint('Error ${isEditing ? 'updating' : 'creating'} subject: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error ${isEditing ? 'updating' : 'creating'} subject: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncNewSubjectToSupabase({
    required int localSubjectId,
    required String code,
    required String name,
    required String yearLevel,
    required String section,
    required Term term,
    required String profId,
    required List<Schedule> schedules,
    String? existingSubjectId,
  }) async {
    final supabase = Supabase.instance.client;
    try {
      String? subjectUuid;

      // Use existing subject ID if provided (from selected subject)
      if (existingSubjectId != null) {
        subjectUuid = existingSubjectId;
      } else {
        // Check if subject exists in Supabase
        final existingSubject = await supabase
            .from('subjects')
            .select('id')
            .eq('code', code)
            .maybeSingle();
        if (existingSubject != null && existingSubject['id'] != null) {
          subjectUuid = existingSubject['id'] as String?;
        }

        // Only create new subject if it doesn't exist
        if (subjectUuid == null) {
          final newSubject = await supabase
              .from('subjects')
              .insert({
                'code': code,
                'name': name,
                'created_at': DateTime.now().toIso8601String(),
                'last_modified': DateTime.now().toIso8601String(),
              })
              .select('id')
              .single();
          subjectUuid = newSubject['id'] as String?;
        }
      }

      if (subjectUuid == null) {
        debugPrint('⚠️ Failed to create subject "$code" in Supabase');
        return;
      }

      final termUuid = await _resolveTermUuid(term);
      if (termUuid == null) {
        debugPrint(
          '⚠️ Unable to sync subject "$code": matching term not found in Supabase',
        );
        return;
      }

      String? offeringUuid;
      final existingOffering = await supabase
          .from('subject_offerings')
          .select('id')
          .eq('local_id', localSubjectId)
          .maybeSingle();
      if (existingOffering != null && existingOffering['id'] != null) {
        offeringUuid = existingOffering['id'] as String?;
      }

      if (offeringUuid == null) {
        final newOffering = await supabase
            .from('subject_offerings')
            .insert({
              'local_id': localSubjectId,
              'year_level': yearLevel,
              'section': section,
              'prof_id': profId,
              'term_id': termUuid,
              'subject_id': subjectUuid,
              'created_at': DateTime.now().toIso8601String(),
              'last_modified': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();
        offeringUuid = newOffering['id'] as String?;
      }

      if (offeringUuid == null) {
        debugPrint(
          '⚠️ Failed to create subject offering for "$code" in Supabase',
        );
        return;
      }

      await (db.update(
        db.subjects,
      )..where((t) => t.id.equals(localSubjectId))).write(
        SubjectsCompanion(
          supabaseId: drift.Value(offeringUuid),
          synced: drift.Value(true),
          lastModified: drift.Value(DateTime.now()),
        ),
      );

      if (schedules.isNotEmpty) {
        final nowIso = DateTime.now().toIso8601String();
        final payloads = schedules.map((schedule) {
          return {
            'local_id': schedule.id,
            'local_subject_id': localSubjectId,
            'subject_id': offeringUuid,
            'day': schedule.day,
            'start_time': schedule.startTime,
            'end_time': schedule.endTime,
            'room': schedule.room ?? '',
            'created_at': nowIso,
            'last_modified': nowIso,
          };
        }).toList();

        final List response = await supabase
            .from('schedules')
            .insert(payloads)
            .select('id, local_id');

        for (final remote in response) {
          final localId = remote['local_id'] as int?;
          final uuid = remote['id'] as String?;
          if (localId == null || uuid == null) continue;
          await (db.update(
            db.schedules,
          )..where((t) => t.id.equals(localId))).write(
            SchedulesCompanion(
              supabaseId: drift.Value(uuid),
              synced: drift.Value(true),
              lastModified: drift.Value(DateTime.now()),
            ),
          );
        }
      }

      debugPrint('✅ Synced new subject "$code" with Supabase');
    } catch (e, st) {
      debugPrint('⚠️ Failed to sync subject "$code": $e\n$st');
    }
  }

  Future<String?> _resolveTermUuid(Term term) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('terms')
          .select('id')
          .eq('term', term.term)
          .eq('start_year', term.startYear)
          .eq('end_year', term.endYear)
          .maybeSingle();
      return response?['id'] as String?;
    } catch (e, st) {
      debugPrint('⚠️ Failed to resolve term UUID: $e\n$st');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingSubject != null ? 'Edit Subject' : 'Add Subject',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Subjects List (toggleable)
              if (widget.existingSubject == null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Subjects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showAvailableSubjects = !_showAvailableSubjects;
                        });
                      },
                      child: Text(
                        _showAvailableSubjects ? 'Hide' : 'Show',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_showAvailableSubjects)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _isLoadingSubjects
                          ? const Center(child: CircularProgressIndicator())
                          : _availableSubjects.isEmpty
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No subjects available'),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _availableSubjects.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final subject = _availableSubjects[index];
                                    final isSelected = _selectedSubject != null &&
                                        _selectedSubject!['id'] == subject['id'];
                                    return ListTile(
                                      tileColor: isSelected
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.15)
                                          : null,
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            Theme.of(context).colorScheme.primary,
                                        child: const Icon(
                                          Icons.book,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      title: Text(
                                        subject['code'] ?? '',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        subject['name'] ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.blueAccent,
                                            )
                                          : null,
                                      onTap: () => _selectSubject(subject),
                                    );
                                  },
                                ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              // Selected Subject Card
              if (_selectedSubject != null &&
                  widget.existingSubject == null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.book,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedSubject!['code'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedSubject!['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _clearSelectedSubject,
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Subject Name and Code Fields (hidden when subject is selected)
              if (_selectedSubject == null ||
                  widget.existingSubject != null) ...[
                FormBuilderTextField(
                  name: 'subjectName',
                  decoration: const InputDecoration(
                    labelText: 'Subject Name',
                    hintText: 'Enter subject name',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 20),

                FormBuilderTextField(
                  name: 'subjectCode',
                  decoration: const InputDecoration(
                    labelText: 'Subject Code',
                    hintText: 'e.g., MATH101',
                    border: OutlineInputBorder(),
                  ),
                  validator: FormBuilderValidators.required(),
                  onChanged: (value) async {
                    if (value != null && value.isNotEmpty) {
                      final exists = await _checkSubjectExists(value);
                      if (exists && _formKey.currentState != null) {
                        _formKey.currentState!.fields['subjectCode']?.invalidate(
                          'This subject code already exists. Please select from available subjects above.',
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],

              FormBuilderDropdown<Term>(
                name: 'term',
                decoration: const InputDecoration(
                  labelText: 'Term',
                  hintText: 'Select term',
                  border: OutlineInputBorder(),
                ),
                items: _terms
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text("${t.term} (${t.startYear}-${t.endYear})"),
                      ),
                    )
                    .toList(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 20),

              FormBuilderDropdown<String>(
                name: 'yearLevel',
                decoration: const InputDecoration(
                  labelText: 'Year Level',
                  hintText: 'Select year level',
                  border: OutlineInputBorder(),
                ),
                items: _gradeLevels
                    .map(
                      (grade) =>
                          DropdownMenuItem(value: grade, child: Text(grade)),
                    )
                    .toList(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 20),

              FormBuilderTextField(
                name: 'section',
                decoration: const InputDecoration(
                  labelText: 'Section',
                  hintText: 'e.g., WMAD, NetSec, etc.',
                  border: OutlineInputBorder(),
                ),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 20),

              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              ..._schedules.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> schedule = entry.value;
                return _buildScheduleRow(index, schedule);
              }).toList(),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _addSchedule,
                icon: const Icon(Icons.add, color: Colors.blue),
                label: const Text(
                  'Add Another Schedule',
                  style: TextStyle(color: Colors.blue),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: createSubject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.existingSubject != null
                            ? 'Save Subject'
                            : 'Create Subject',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleRow(int index, Map<String, dynamic> schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: schedule['day']?.isEmpty == true
                      ? null
                      : schedule['day'],
                  decoration: const InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: _days.map((String day) {
                    return DropdownMenuItem<String>(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _schedules[index]['day'] = value ?? '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),

              if (_schedules.length > 1)
                IconButton(
                  onPressed: () => _removeSchedule(index),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: FormBuilderDateTimePicker(
                  name: 'startTime_${index}',
                  inputType: InputType.time,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _schedules[index]['startTime'] = value != null
                          ? DateFormat('HH:mm').format(value)
                          : '';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FormBuilderDateTimePicker(
                  name: 'endTime_${index}',
                  inputType: InputType.time,
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _schedules[index]['endTime'] = value != null
                          ? DateFormat('HH:mm').format(value)
                          : '';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          FormBuilderTextField(
            name: 'room_${index}',
            decoration: const InputDecoration(
              labelText: 'Room Number',
              hintText: 'e.g., Centrum 1,Room 201',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            validator: FormBuilderValidators.required(),
            onChanged: (value) {
              setState(() {
                _schedules[index]['room'] = value ?? '';
              });
            },
          ),
        ],
      ),
    );
  }

  void _addSchedule() {
    setState(() {
      _schedules.add({'day': '', 'startTime': '', 'endTime': ''});
    });
  }

  void _removeSchedule(int index) {
    setState(() {
      _schedules.removeAt(index);
    });
  }

  // void _createSubject() {
  //   if (_formKey.currentState!.saveAndValidate()) {
  //     // Form is valid - you can access form data with _formKey.currentState!.value
  //     // and add your own database logic here
  //   }
  // }
}
