# 1. Obter dependências
flutter pub get

# 2. Verificar formatação (vai falhar se não estiver formatado)
dart format --output=none --set-exit-if-changed lib test

# 3. Análise estática (procura erros de código)
flutter analyze

# 4. Correr testes de widget
# As credenciais do Supabase são injectadas via --dart-define-from-file
flutter test --dart-define-from-file=.env

# 5. Correr o teste de integração (smoke test)
flutter test --dart-define-from-file=.env test/integration_test/app_test.dart

# Nota: para correr a app em desenvolvimento usa:
#   flutter run --dart-define-from-file=.env
# O ficheiro .env está no .gitignore — nunca commitar credenciais em plain-text.
