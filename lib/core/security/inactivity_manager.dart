import 'dart:async';
import 'package:flutter/material.dart';

class InactivityManager extends ChangeNotifier {
  static const Duration _timeout = Duration(seconds: 30);


  Timer? _timer;
  bool _sessionExpired = false;

  bool get sessionExpired => _sessionExpired;

  void resetTimer() {
    _timer?.cancel();
    if (_sessionExpired) return;
    _timer = Timer(_timeout, _onTimeout);
  }

  void _onTimeout() {
    _sessionExpired = true;
    notifyListeners();
  }

  void resetSession() {
    _sessionExpired = false;
    resetTimer();
  }

  void stopTimer() {
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}