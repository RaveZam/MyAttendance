import 'package:flutter/material.dart';

class AccountTypeHandler extends ChangeNotifier {
  String _accountType = '';
  String get accountType => _accountType;

  void setAccountType(String accountType) {
    _accountType = accountType;
    notifyListeners();
  }
}
