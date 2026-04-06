import 'package:supabase_flutter/supabase_flutter.dart';

/// Domain representation of an authenticated user, combining data from
/// Supabase Auth (`auth.users`) and the application's `profiles` table.
class UserModel {
  /// Supabase Auth UUID — matches `profiles.id`.
  final String id;

  /// Auth email address.
  final String? email;

  // ---------- profiles table ----------

  /// Full name from the `profiles` table.
  final String? fullName;

  /// Date of birth from `profiles.date_of_birth` (ISO-8601 string).
  final String? dateOfBirth;

  /// Phone number from `profiles.phone`.
  final String? phone;

  const UserModel({
    required this.id,
    this.email,
    this.fullName,
    this.dateOfBirth,
    this.phone,
  });

  // ---------------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------------

  /// Constructs a [UserModel] from the Supabase [User] alone (no profile yet).
  factory UserModel.fromSupabaseUser(User user) {
    return UserModel(id: user.id, email: user.email);
  }

  /// Merges a Supabase [User] with a profile row fetched from the DB.
  factory UserModel.fromSupabaseUserAndProfile(
    User user,
    Map<String, dynamic> profile,
  ) {
    return UserModel(
      id: user.id,
      email: user.email,
      fullName: profile['full_name'] as String?,
      dateOfBirth: profile['date_of_birth'] as String?,
      phone: profile['phone'] as String?,
    );
  }

  /// Creates an updated copy of this model with the supplied profile fields.
  UserModel copyWithProfile(Map<String, dynamic> profile) {
    return UserModel(
      id: id,
      email: email,
      fullName: profile['full_name'] as String?,
      dateOfBirth: profile['date_of_birth'] as String?,
      phone: profile['phone'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  /// Friendly label: prefers `fullName`, falls back to email prefix, then 'User'.
  String get displayLabel {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    if (email != null && email!.isNotEmpty) return email!.split('@').first;
    return 'Utilizador';
  }

  @override
  String toString() => 'UserModel(id: $id, email: $email, fullName: $fullName)';
}
