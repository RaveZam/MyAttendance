import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:myattendance/core/database/app_database.dart';

class ImportSchedule {
  final db = AppDatabase();

  Future<List<Map<String, dynamic>>?> importSchedule() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      final csvString = await file.readAsString(encoding: latin1);

      final rows = const CsvToListConverter().convert(csvString);

      final headers = rows.first.cast<String>();
      final data = rows.skip(1).map((row) {
        return Map.fromIterables(headers, row);
      }).toList();

      await saveToDatabase(data);
      // debugPrint(jsonEncode(data));
      return data;
    } else {
      debugPrint('User canceled the picker or Invalid FIle Type');
      return null;
    }
  }

  Future<void> saveToDatabase(List<Map<String, dynamic>> data) async {
    try {
      final entries = data.map((row) {
        final normalizedRow = {
          for (var entry in row.entries) entry.key.toLowerCase(): entry.value,
        };
        return SchedulesCompanion.insert(
          subject: normalizedRow["subject"] as String,
          day: normalizedRow["day"] as String,
          time: normalizedRow["time"] as String,
          room: normalizedRow["room"] as String,
        );
      }).toList();

      await db.insertSchedules(entries);
      debugPrint('Data saved to database');

      final schedules = await db.getAllSchedules();
      for (var s in schedules) {
        debugPrint('${s.subject} - ${s.day} at ${s.time} in ${s.room}');
      }
    } catch (e) {
      debugPrint('Error saving to database: $e');
    }
  }
}
