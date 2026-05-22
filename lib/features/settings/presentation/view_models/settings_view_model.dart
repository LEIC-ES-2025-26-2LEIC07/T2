import 'dart:async';

import 'package:flutter/material.dart';
import 'package:clinic_go/features/auth/domain/auth_service.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required AuthService authService})
    : _auth = authService {
    _loadFromMetadata();
  }

  final AuthService _auth;

  List<String> _conditions = [];
  List<String> _allergies = [];
  List<String> _rawSchedules = []; // stored as "HH:mm"

  bool _isSaving = false;
  String? _errorMessage;

  List<String> get conditions => List.unmodifiable(_conditions);
  List<String> get allergies => List.unmodifiable(_allergies);
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<TimeOfDay> get schedules =>
      _rawSchedules.map(_parseTime).toList();

  void reload() {
    _loadFromMetadata();
  }

  void _loadFromMetadata() {
    final meta = _auth.currentUserMetadata;
    _conditions = _toStringList(meta['health_conditions']);
    _allergies = _toStringList(meta['health_allergies']);
    _rawSchedules = _toStringList(meta['routine_schedules']);
    notifyListeners();
  }

  Future<void> saveConditionsAndAllergies(
    List<String> conditions,
    List<String> allergies,
  ) async {
    _conditions = List.from(conditions);
    _allergies = List.from(allergies);
    notifyListeners();
    await _persist();
  }

  Future<void> saveSchedules(List<TimeOfDay> schedules) async {
    _rawSchedules = schedules.map(_formatTime).toList();
    notifyListeners();
    await _persist();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _persist() async {
    final email = _auth.currentUserEmail;
    if (email == null) return;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _auth.updateProfile(
        email: email,
        metadata: {
          ..._auth.currentUserMetadata,
          'health_conditions': _conditions,
          'health_allergies': _allergies,
          'routine_schedules': _rawSchedules,
        },
      );
    } catch (_) {
      _errorMessage = 'Erro ao guardar as definições.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) return value.whereType<String>().toList();
    return [];
  }

  static TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
