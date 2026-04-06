import 'package:flutter/material.dart';
import 'package:clinic_go/data/repositories/auth_repository.dart';

/// ViewModel for the Profile feature.
///
/// Currently the profile data is served directly through [AuthViewModel].
/// This class is kept for future profile-editing logic (update name, phone, etc.).
class ProfileViewModel extends ChangeNotifier {
  // ignore: unused_field — kept for future updateProfile() implementation
  final AuthRepository _repo;

  ProfileViewModel({AuthRepository? repo})
    : _repo = repo ?? AuthRepository.instance;

  // Future: add updateProfile(fullName, phone, dateOfBirth) here,
  // calling _repo and then notifying listeners.
}
