# 1. Obter dependências
flutter pub get

# 2. Verificar formatação (vai falhar se não estiver formatado)
dart format --output=none --set-exit-if-changed lib test

# 3. Análise estática (procura erros de código)
flutter analyze

# 4. Correr testes de widget
flutter test

# 5. Correr o teste de integração (smoke test)
flutter test test/integration_test/app_test.dart

