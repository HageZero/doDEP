import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = false;
  bool _showMessage = false;
  bool _showVideo = false;

  bool get isEnglish => _isEnglish;
  bool get showMessage => _showMessage;
  bool get showVideo => _showVideo;

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    if (_isEnglish) {
      _showMessage = true;
      _showVideo = false;
      Future.delayed(const Duration(milliseconds: 1500), () {
        _showMessage = false;
        _showVideo = true;
        notifyListeners();
      });
    } else {
      _showMessage = false;
      _showVideo = false;
    }
    notifyListeners();
  }

  void hideVideo() {
    _showVideo = false;
    _isEnglish = false;
    notifyListeners();
  }
} 