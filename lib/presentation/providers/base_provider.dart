import 'package:flutter/material.dart';

enum ViewState { idle, loading, error, empty }

class BaseProvider extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String _errorMessage = '';

  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  bool get isLoading => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;
  bool get isEmpty => _state == ViewState.empty;

  void setLoading() {
    _state = ViewState.loading;
    _errorMessage = '';
    notifyListeners();
  }

  void setIdle() {
    _state = ViewState.idle;
    notifyListeners();
  }

  void setError(String message) {
    _state = ViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void setEmpty() {
    _state = ViewState.empty;
    notifyListeners();
  }
}
