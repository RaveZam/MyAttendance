import 'package:flutter/material.dart';

class QrDataProvider extends ChangeNotifier {
  String _studentID = "", _studentName = "";
  String get studentID => _studentID;
  String get studentName => _studentName;

  String _classCode = "";
  String _classSessionId = "";
  String _instructorName = "";
  String _startTime = "";
  String _endTime = "";

  bool _scanSuccess = false;

  String get classCode => _classCode;
  String get classSessionId => _classSessionId;
  String get instructorName => _instructorName;
  String get startTime => _startTime;
  String get endTime => _endTime;

  bool get scanSuccess => _scanSuccess;

  void setScanSuccess(bool success) {
    _scanSuccess = success;
    notifyListeners();
  }

  void setStudentID(String id) {
    _studentID = id;
    notifyListeners();
  }

  void setStudentName(String name) {
    _studentName = name;
    notifyListeners();
  }

  void setClassData(
    String classCode,
    String classSessionId,
    String instructorName,
    String startTime,
    String endTime,
  ) {
    _classCode = classCode;
    _classSessionId = classSessionId;
    _instructorName = instructorName;
    _startTime = startTime;
    _endTime = endTime;
    notifyListeners();
  }
}
