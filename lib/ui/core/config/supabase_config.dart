class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void validate() {
    final parsedUrl = Uri.tryParse(url);

    if (url.isEmpty || parsedUrl == null || !parsedUrl.hasScheme || parsedUrl.host.isEmpty) {
      throw StateError(
        'Configuração do Supabase inválida: define SUPABASE_URL com o URL do projeto '
        '(ex.: https://teu-projeto.supabase.co).',
      );
    }

    if (parsedUrl.host.startsWith('sb_publishable_')) {
      throw StateError(
        'SUPABASE_URL está errado: estás a usar a publishable key no campo do URL. '
        'Usa o Project URL do Supabase.',
      );
    }

    if (anonKey.isEmpty) {
      throw StateError(
        'Configuração do Supabase inválida: define SUPABASE_ANON_KEY com a publishable/anon key.',
      );
    }

    if (anonKey.startsWith('sb_secret_')) {
      throw StateError(
        'SUPABASE_ANON_KEY está errado: a secret key não pode ficar na app cliente. '
        'Usa a publishable/anon key.',
      );
    }
  }
}
