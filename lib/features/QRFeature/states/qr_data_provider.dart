import 'package:flutter/material.dart';

class QrDataProvider extends ChangeNotifier {
  String _studentID = "", _studentName = "";
  String get studentID => _studentID;
  String get studentName => _studentName;

  void setStudentID(String id) {
    _studentID = id;
    notifyListeners();
  }

  void setStudentName(String name) {
    _studentName = name;
    notifyListeners();
  }
}
