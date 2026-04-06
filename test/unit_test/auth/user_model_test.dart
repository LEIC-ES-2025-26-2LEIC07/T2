import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_go/domain/models/user_model.dart';

void main() {
  // ─── Constructor / direct creation ─────────────────────────────────────────

  group('UserModel constructor', () {
    test('stores all provided fields', () {
      const m = UserModel(
        id: 'id-1',
        email: 'a@b.com',
        fullName: 'Alice',
        dateOfBirth: '1990-01-01',
        phone: '912345678',
      );

      expect(m.id, 'id-1');
      expect(m.email, 'a@b.com');
      expect(m.fullName, 'Alice');
      expect(m.dateOfBirth, '1990-01-01');
      expect(m.phone, '912345678');
    });

    test('allows nullable optional fields', () {
      const m = UserModel(id: 'id-2');
      expect(m.email, isNull);
      expect(m.fullName, isNull);
      expect(m.dateOfBirth, isNull);
      expect(m.phone, isNull);
    });
  });

  // ─── displayLabel ──────────────────────────────────────────────────────────

  group('displayLabel', () {
    test('returns fullName when provided', () {
      const m = UserModel(id: 'x', email: 'z@z.com', fullName: 'Bob');
      expect(m.displayLabel, 'Bob');
    });

    test('returns email prefix when fullName is null', () {
      const m = UserModel(id: 'x', email: 'bob@example.com');
      expect(m.displayLabel, 'bob');
    });

    test('returns email prefix when fullName is empty string', () {
      const m = UserModel(id: 'x', email: 'carol@test.org', fullName: '');
      expect(m.displayLabel, 'carol');
    });

    test('returns Utilizador when both fullName and email are null', () {
      const m = UserModel(id: 'x');
      expect(m.displayLabel, 'Utilizador');
    });

    test('returns Utilizador when email is empty string', () {
      const m = UserModel(id: 'x', email: '');
      expect(m.displayLabel, 'Utilizador');
    });
  });

  // ─── copyWithProfile ───────────────────────────────────────────────────────

  group('copyWithProfile', () {
    const base = UserModel(id: 'uid', email: 'u@mail.com');

    test('returns a new UserModel with profile fields populated', () {
      final copy = base.copyWithProfile({
        'full_name': 'Carlos',
        'date_of_birth': '1985-06-15',
        'phone': '961111111',
      });

      expect(copy.id, 'uid');
      expect(copy.email, 'u@mail.com');
      expect(copy.fullName, 'Carlos');
      expect(copy.dateOfBirth, '1985-06-15');
      expect(copy.phone, '961111111');
    });

    test('nulls out optional fields when map contains null values', () {
      final copy = base.copyWithProfile({
        'full_name': null,
        'date_of_birth': null,
        'phone': null,
      });

      expect(copy.fullName, isNull);
      expect(copy.dateOfBirth, isNull);
      expect(copy.phone, isNull);
    });

    test('preserves id and email from the original model', () {
      final copy = base.copyWithProfile({'full_name': 'X'});
      expect(copy.id, base.id);
      expect(copy.email, base.email);
    });
  });

  // ─── fromSupabaseUserAndProfile ────────────────────────────────────────────

  group('fromSupabaseUserAndProfile-like via copyWithProfile', () {
    test('merges auth id and email with profile data correctly', () {
      // We exercise the copyWithProfile path directly (same logic as
      // fromSupabaseUserAndProfile) to avoid importing the full Supabase SDK.
      const auth = UserModel(id: 'auth-id', email: 'auth@mail.com');
      final merged = auth.copyWithProfile({
        'full_name': 'Merge Test',
        'date_of_birth': '2000-12-31',
        'phone': '931234567',
      });

      expect(merged.id, 'auth-id');
      expect(merged.email, 'auth@mail.com');
      expect(merged.fullName, 'Merge Test');
    });
  });

  // ─── toString ─────────────────────────────────────────────────────────────

  group('toString', () {
    test('includes id, email and fullName', () {
      const m = UserModel(id: 'i', email: 'e@e.com', fullName: 'F');
      expect(m.toString(), 'UserModel(id: i, email: e@e.com, fullName: F)');
    });
  });
}
