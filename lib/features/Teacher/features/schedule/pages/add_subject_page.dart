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
    if (widget.existingSubject != null) {
      _populateFormWithExistingData();
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
          final subjectCompanion = SubjectsCompanion(
            subjectCode: drift.Value(subject['subjectCode']),
            subjectName: drift.Value(subject['subjectName']),
            termId: drift.Value(subject['term'].id),
            yearLevel: drift.Value(subject['yearLevel']),
            section: drift.Value(subject['section']),
            profId: drift.Value(profId.toString()),
            synced: drift.Value(false),
          );

          final subjectId = await db.insertSubject(subjectCompanion);

          // Ensure term_id is set on the subject row (use raw update to be resilient
          // against out-of-date generated companions)
          await db.setSubjectTerm(subjectId, subject['term'].id);

          if (scheduleObjects.isNotEmpty) {
            List<SchedulesCompanion> scheduleCompanions = scheduleObjects.map((
              schedule,
            ) {
              return SchedulesCompanion(
                subjectId: drift.Value(subjectId),
                day: drift.Value(schedule['day']),
                startTime: drift.Value(schedule['startTime']),
                endTime: drift.Value(schedule['endTime']),
                room: drift.Value(schedule['room']),
                synced: drift.Value(false),
              );
            }).toList();

            await db.insertSchedules(scheduleCompanions);
          }

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
              ),
              const SizedBox(height: 20),

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
