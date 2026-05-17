// Real integration test — hits the actual Supabase database.
// Runs step-by-step to isolate exactly where addMedication fails.
//
// Run with:
// flutter test test/features/medication/data/add_medication_integration_test.dart \
//   --dart-define=SUPABASE_URL=https://pizwimuaqaafcgfibkdy.supabase.co \
//   --dart-define=SUPABASE_ANON_KEY=sb_secret_keDm_RYq9eICBxw1Pvty8g_5Wf3E7I5 \
//   --dart-define=TEST_EMAIL=a@a.pt \
//   --dart-define=TEST_PASSWORD=123456

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:clinic_go/features/medication/data/medication_repository.dart';
import 'package:clinic_go/features/medication/data/supabase_medication_repository.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');

const _hasCredentials =
    _url != '' && _anonKey != '' && _email != '' && _password != '';

void _log(String step, String msg) => debugPrint('[$step] $msg');

void _logPostgrestError(String step, PostgrestException e) {
  debugPrint('[$step] PostgrestException:');
  debugPrint('  code   : ${e.code}');
  debugPrint('  message: ${e.message}');
  debugPrint('  details: ${e.details}');
  debugPrint('  hint   : ${e.hint}');
}

void main() {
  if (!_hasCredentials) {
    test(
      'integration tests skipped — pass --dart-define=SUPABASE_URL=... to run',
      () {},
      skip: 'no credentials provided via --dart-define',
    );
    return;
  }

  late SupabaseClient client;
  String? cleanupId;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(url: _url, anonKey: _anonKey);
    } catch (_) {
      // Already initialized in a previous test run in the same process.
    }
    client = Supabase.instance.client;
  });

  setUp(() async {
    final res = await client.auth.signInWithPassword(
      email: _email,
      password: _password,
    );
    _log('setUp', 'signed in as ${res.user?.email ?? 'UNKNOWN'}');
  });

  tearDown(() async {
    if (cleanupId != null) {
      try {
        await client.from('medications').delete().eq('id', cleanupId!);
        _log('tearDown', 'deleted test medication $cleanupId');
      } catch (e) {
        _log('tearDown', 'cleanup failed: $e');
      }
      cleanupId = null;
    }
    await client.auth.signOut();
  });

  group('addMedication — real Supabase integration', () {
    // ── Step 1 ────────────────────────────────────────────────────────────────
    // Verifies that sign-in works and currentUser is populated.
    // If this fails: auth credentials are wrong or the account doesn't exist.
    test('Step 1 — sign-in gives a valid currentUser', () async {
      final user = client.auth.currentUser;
      _log('STEP 1', 'currentUser id=${user?.id}  email=${user?.email}');
      expect(user, isNotNull, reason: 'Sign-in failed — currentUser is null');
    });

    // ── Step 2 ────────────────────────────────────────────────────────────────
    // Raw INSERT into medications.
    // If this fails: look at code/message for RLS violations or schema mismatches.
    test('Step 2 — raw insert into medications table', () async {
      final user = client.auth.currentUser!;
      try {
        final row = await client
            .from('medications')
            .insert({
              'user_id': user.id,
              'name': 'Integration Test Med',
              'dosage': 10,
              'dosage_unit': 'mg',
              'frequency': 'Daily',
              'color': '#3D6BE0',
              'with_food': false,
            })
            .select('id')
            .single();

        cleanupId = row['id'] as String;
        _log('STEP 2', 'inserted medication id=$cleanupId');
        expect(cleanupId, isNotEmpty);
      } on PostgrestException catch (e) {
        _logPostgrestError('STEP 2', e);
        rethrow;
      }
    });

    // ── Step 3 ────────────────────────────────────────────────────────────────
    // Raw INSERT into medication_reminders with a real medication_id.
    // If this fails: likely a days_of_week TEXT[] serialization issue or RLS.
    test('Step 3 — raw insert into medication_reminders table', () async {
      final user = client.auth.currentUser!;

      // Create parent medication first.
      final medRow = await client
          .from('medications')
          .insert({
            'user_id': user.id,
            'name': 'Integration Test Med (reminders)',
            'dosage': 10,
            'dosage_unit': 'mg',
            'frequency': 'Daily',
            'color': '#3D6BE0',
            'with_food': false,
          })
          .select('id')
          .single();

      cleanupId = medRow['id'] as String;

      try {
        final remRows = await client.from('medication_reminders').insert({
          'medication_id': cleanupId,
          'reminder_time': '08:00:00',
          'days_of_week': [
            'monday',
            'tuesday',
            'wednesday',
            'thursday',
            'friday',
            'saturday',
            'sunday',
          ],
          'is_active': true,
        }).select();

        _log('STEP 3', 'inserted reminders: $remRows');
        expect(remRows, isNotEmpty);
      } on PostgrestException catch (e) {
        _logPostgrestError('STEP 3', e);
        rethrow;
      }
    });

    // ── Step 4 ────────────────────────────────────────────────────────────────
    // Full addMedication via the repository — the exact production path.
    // If Steps 2 and 3 pass but this fails: logic issue inside the repository.
    test(
      'Step 4 — full addMedication via SupabaseMedicationRepository',
      () async {
        final repo = SupabaseMedicationRepository(client);

        const payload = AddMedicationPayload(
          name: 'Integration Test Med (full)',
          dosageAmount: 50,
          dosageUnit: 'mg',
          frequency: 'Twice daily',
          color: Color(0xFF3D6BE0),
          reminderTimes: ['08:00:00', '20:00:00'],
          daysOfWeek: ['monday', 'wednesday', 'friday'],
        );

        try {
          final result = await repo.addMedication(payload);
          cleanupId = result.medicationId;
          _log('STEP 4', 'medicationId=${result.medicationId}');
          _log('STEP 4', 'reminders saved: ${result.reminders.length}');
          expect(result.medicationId, isNotEmpty);
          expect(result.reminders, hasLength(2));
        } on MedicationSaveException catch (e) {
          _log('STEP 4', 'MedicationSaveException: ${e.message}');
          rethrow;
        } on PostgrestException catch (e) {
          _logPostgrestError('STEP 4', e);
          rethrow;
        }
      },
    );
  });
}
