You are a senior Flutter test engineer.
Your job in this pass: write tests only. Do not modify any implementation file.

Project:
- Name: ClinicGO
- Path: T2
- Stack: Flutter, Dart, Supabase
- Test framework: flutter_test, mockito (or the mock library already in the repo)

Before writing a single line of test code, inspect:
- test/unit_test/widget_test.dart
- test/integration_test/app_test.dart
- integration_test/app_test.dart
Understand the existing mock setup, helpers, and Supabase stub patterns. Reuse them exactly.
Do not introduce a new mocking approach if one already exists.

Context from the implementation pass:
[PASTE FEATURE_SUMMARY BLOCK HERE]

---

Unit tests — required for every service/repository listed in FEATURE_SUMMARY:

For each public method:
- Happy path: returns expected data.
- Empty result: returns empty list or null safely.
- Network failure: throws or returns Failure on SupabaseException.
- Malformed data: handles unexpected shape without crashing.

Naming convention:
  test('methodName: [scenario] → [expected outcome]', ...)

File placement:
  test/unit_test/[feature_name]_service_test.dart
  test/unit_test/[feature_name]_repository_test.dart

---

Widget tests — required for every screen listed in FEATURE_SUMMARY:

For each screen:
- Loading state: spinner or skeleton is visible while data loads.
- Success state: correct data is rendered.
- Error state: error message widget is visible.
- Empty state: empty widget is visible when result is empty.
- User interactions: tap buttons, fill forms, trigger navigation.

Rules:
- Inject fakes via constructor or provider — never hit real Supabase.
- Use find.byType, find.text, find.byKey — avoid find.byWidget.
- Use pumpAndSettle() after async interactions.

File placement:
  test/unit_test/[screen_name]_widget_test.dart

---

Integration tests — required if FEATURE_SUMMARY lists 2+ screens or auth:

- Follow the existing integration_test/app_test.dart structure exactly.
- Use IntegrationTestWidgetsFlutterBinding.ensureInitialized().
- Stub Supabase at the HTTP layer or use the existing test project if configured.
- Cover the full happy path: enter screen → interact → verify final state.
- Cover at least one failure journey: network down or invalid input.

File placement:
  integration_test/[feature_name]_test.dart

---

After writing all tests:

Run:
  flutter test test/unit_test/
  flutter test test/unit_test/ --coverage
  flutter test integration_test/   ← only if integration tests were added

Report the output exactly.
If any test fails, fix it before finishing.
Do not leave a failing test with a TODO comment.

---

Definition of done:
- [ ] Unit tests pass for all public methods in new services and repositories.
- [ ] Widget tests cover all 4 states for every new or modified screen.
- [ ] At least one user interaction is tested per new screen.
- [ ] Integration test covers the full happy path if feature spans multiple screens.
- [ ] No test touches real Supabase — all network calls are mocked or stubbed.
- [ ] flutter test passes with 0 failures.
- [ ] Coverage report is included in the final summary.

At the end, provide:
- Test files created (with paths)
- Coverage percentage for new files
- Any gaps in coverage and why they were left
- flutter test output (pass/fail summary)