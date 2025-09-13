import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

class ImportSchedule {
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

      debugPrint(jsonEncode(data));
      return data;
    } else {
      debugPrint('User canceled the picker or Invalid FIle Type');
      return null;
    }
  }
}
