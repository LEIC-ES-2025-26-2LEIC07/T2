import 'package:clinic_go/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _defaultSupabaseUrl =
    'https://sb_publishable_e-bQdp8wGizIL1py2JMrSg_3GZtj_Lz.supabase.co';
const _defaultSupabaseAnonKey = 'sb_secret_8-OsrH4yDDnRHgOHj4Ls3Q_HNovhjgC';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeSupabase();
  runApp(const ProviderScope(child: ClinicGoApp()));
}

Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: _defaultSupabaseUrl,
      ),
      anonKey: const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: _defaultSupabaseAnonKey,
      ),
    );
  } catch (_) {
    // Ignore duplicate initialization in tests.
  }
}
