import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_go/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test(
      'validate throws StateError when SUPABASE_URL env var is not defined',
      () {
        // In the test environment no --dart-define is passed, so both
        // SUPABASE_URL and SUPABASE_ANON_KEY are empty strings at compile-time.
        // validate() should detect the empty URL and throw.
        expect(SupabaseConfig.validate, throwsA(isA<StateError>()));
      },
    );

    test('validate error message mentions SUPABASE_URL', () {
      expect(
        SupabaseConfig.validate,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_URL'),
          ),
        ),
      );
    });
  });
}
