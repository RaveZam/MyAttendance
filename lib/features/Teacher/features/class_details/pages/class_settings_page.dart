import 'package:flutter/material.dart';
import 'package:myattendance/core/database/app_database.dart';
import 'package:numberpicker/numberpicker.dart';

class ClassSettingsPage extends StatefulWidget {
  final String classID;

  const ClassSettingsPage({
    super.key,
    required this.classID,
  });

  @override
  State<ClassSettingsPage> createState() => _ClassSettingsPageState();
}

class _ClassSettingsPageState extends State<ClassSettingsPage> {
  final db = AppDatabase.instance;
  int _lateTimeMinutes = 20;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadLateTime();
  }

  Future<void> _loadLateTime() async {
    try {
      final subjectId = int.parse(widget.classID);
      final subjects = await db.getSubjectByID(subjectId);
      if (subjects.isNotEmpty) {
        setState(() {
          _lateTimeMinutes = subjects.first.lateAfterMinutes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading late time: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLateTime() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final subjectId = int.parse(widget.classID);
      await db.updateLateTime(subjectId, _lateTimeMinutes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Late time updated to $_lateTimeMinutes minutes'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      debugPrint('Error saving late time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Class Settings',
          style: TextStyle(
            color: scheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveLateTime,
              child: Text(
                'Save',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: scheme.primary),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Late Time Per Session',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Students will be marked as late if they arrive after this many minutes from the session start time.',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Column(
                          children: [
                            NumberPicker(
                              value: _lateTimeMinutes,
                              minValue: 0,
                              maxValue: 120,
                              step: 5,
                              itemHeight: 60,
                              selectedTextStyle: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                              textStyle: TextStyle(
                                fontSize: 24,
                                color: scheme.onSurfaceVariant,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: scheme.outlineVariant,
                                    width: 1,
                                  ),
                                  bottom: BorderSide(
                                    color: scheme.outlineVariant,
                                    width: 1,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _lateTimeMinutes = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '$_lateTimeMinutes ${_lateTimeMinutes == 1 ? 'minute' : 'minutes'}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: scheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This setting applies to all future sessions for this class.',
                              style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
