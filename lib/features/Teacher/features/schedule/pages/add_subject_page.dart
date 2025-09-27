import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';

class AddSubjectPage extends StatefulWidget {
  const AddSubjectPage({super.key});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  final List<Map<String, dynamic>> _schedules = [
    {'day': '', 'startTime': '', 'endTime': ''},
  ];

  final List<String> _terms = ['1st Semester', 'Midterm', '2nd Semester'];
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

  final db = AppDatabase.instance;

  void createSubject() async {
    if (_formKey.currentState!.saveAndValidate()) {
      final subject = _formKey.currentState!.value;
      final profId = Supabase.instance.client.auth.currentUser?.id;

      // Create schedule objects from the _schedules data
      List<Map<String, dynamic>> scheduleObjects = [];
      for (int i = 0; i < _schedules.length; i++) {
        if (_schedules[i]['day'].isNotEmpty) {
          scheduleObjects.add({
            'day': _schedules[i]['day'],
            'startTime': _schedules[i]['startTime'],
            'endTime': _schedules[i]['endTime'],
            'room': _schedules[i]['room'] ?? '',
          });
        }
      }

      try {
        // Insert the subject first
        final subjectCompanion = SubjectsCompanion(
          subjectCode: drift.Value(subject['subjectCode']),
          subjectName: drift.Value(subject['subjectName']),
          term: drift.Value(subject['term']),
          yearLevel: drift.Value(subject['yearLevel']),
          section: drift.Value(subject['section']),
          profId: drift.Value(profId.toString()),
        );

        final subjectId = await db.insertSubject(subjectCompanion);

        // Insert schedules if any exist
        if (scheduleObjects.isNotEmpty) {
          List<SchedulesCompanion> scheduleCompanions = scheduleObjects.map((
            schedule,
          ) {
            return SchedulesCompanion(
              subjectId: drift.Value(subjectId),
              day: drift.Value(schedule['day']),
              startTime: drift.Value(schedule['startTime']),
              endTime: drift.Value(schedule['endTime']),
              roomNumber: drift.Value(schedule['room']),
            );
          }).toList();

          await db.insertSchedules(scheduleCompanions);
        }

        // Debug print the structured data
        debugPrint('Subject: ${subject.toString()}');
        debugPrint('Schedules: ${scheduleObjects.toString()}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject and schedules created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } catch (e) {
        debugPrint('Error creating subject: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating subject: $e'),
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
        title: const Text(
          'Add Subject',
          style: TextStyle(
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
              // Subject Name
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

              // Subject Code
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

              // Term Dropdown
              FormBuilderDropdown<String>(
                name: 'term',
                decoration: const InputDecoration(
                  labelText: 'Term',
                  hintText: 'Select term',
                  border: OutlineInputBorder(),
                  // suffixIcon: Icon(Icons.keyboard_arrow_down),
                ),
                items: _terms
                    .map(
                      (term) =>
                          DropdownMenuItem(value: term, child: Text(term)),
                    )
                    .toList(),
                validator: FormBuilderValidators.required(),
              ),
              const SizedBox(height: 20),

              // Grade Level Dropdown
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

              // Section
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

              // Schedule Section
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Dynamic Schedule Fields - Optimized
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
                      child: const Text(
                        'Create Subject',
                        style: TextStyle(
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
          // First row: Day and Remove button
          Row(
            children: [
              // Day Dropdown (Monday-Friday only)
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

              // Remove button
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

          // Second row: Start Time and End Time with Time Pickers
          Row(
            children: [
              // Start Time with Time Picker
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

              // End Time with Time Picker
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

          // Third row: Room Number
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

  //
  //   }
  // }
}
