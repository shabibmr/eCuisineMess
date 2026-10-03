import 'package:flutter/material.dart';
import '../models/rfid_tap_result.dart';
import '../services/api_service.dart';

class CounterProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  RFIDTapResult? _currentTap;
  RFIDTapResult? get currentTap => _currentTap;

  Map<String, dynamic>? _lastIssuedBill;
  Map<String, dynamic>? get lastIssuedBill => _lastIssuedBill;

  Map<String, dynamic>? _activeMealWindow;
  Map<String, dynamic>? get activeMealWindow => _activeMealWindow;

  bool _isOverride = false;
  bool get isOverride => _isOverride;

  String? _overrideBy;
  String? _overrideReason;

  Future<void> initMealWindow() async {
    try {
      final winData = await _api.getCurrentMealWindow();
      _activeMealWindow = winData['window'];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> scanRfid(String rfidTag) async {
    _isLoading = true;
    _errorMessage = null;
    _isOverride = false;
    _overrideBy = null;
    _overrideReason = null;
    _lastIssuedBill = null;
    notifyListeners();

    try {
      _currentTap = await _api.tapRfid(rfidTag);
      if (!_currentTap!.success) {
        _errorMessage = _currentTap!.message ?? 'Validation failed';
      }
    } catch (e) {
      _errorMessage = 'Connection error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void grantSupervisorOverride(String supervisorName, String reason) {
    _isOverride = true;
    _overrideBy = supervisorName;
    _overrideReason = reason;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> issueToken() async {
    if (_currentTap == null) return false;
    final memberId = _currentTap!.memberData?['id'];
    if (memberId == null) return false;

    final mealType = _currentTap!.mealType ?? _activeMealWindow?['meal_type'] ?? 'LUNCH';

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.issueToken(
        memberId: memberId is int ? memberId : int.parse(memberId.toString()),
        mealType: mealType,
        isOverride: _isOverride ? 1 : 0,
        overrideBy: _overrideBy,
        overrideReason: _overrideReason,
      );

      if (res['success'] == true) {
        _lastIssuedBill = res['bill'];
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to issue token';
      }
    } catch (e) {
      _errorMessage = 'Failed to print/save bill: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  void clearCounter() {
    _currentTap = null;
    _errorMessage = null;
    _isOverride = false;
    _overrideBy = null;
    _overrideReason = null;
    _lastIssuedBill = null;
    notifyListeners();
  }
}
