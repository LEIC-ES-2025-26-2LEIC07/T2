# AI Feature Prompt Template for ClinicGO

Use this prompt when you want another AI to add a new feature to the `T2` Flutter app with minimal back-and-forth.

## How to use

1. Copy the template below.
2. Replace every `[PLACEHOLDER]` with your feature details.
3. Paste the completed prompt into the AI tool.
4. If the feature includes backend or Supabase work, include the exact table and field names.
5. If there is a GitHub issue, paste the full issue body into the `Feature specification` section.

## Full prompt template

```text
You are a senior Flutter engineer working directly in my existing repository.

Project:
- Name: ClinicGO
- Path: T2
- Stack: Flutter, Dart, Supabase
- Current app state: early-stage app with a lightweight feature-based structure
- Existing patterns matter more than idealized architecture

Core instructions:
- Inspect the current codebase first before making changes.
- Implement the feature end-to-end in the real app, not as a disconnected demo.
- Reuse the current structure, naming, theme, and navigation patterns where possible.
- Make the smallest clean set of changes that fully delivers the feature.
- Do not refactor unrelated code unless it is necessary to complete the task safely.
- Keep the code production-oriented, readable, and testable.
- Prefer simple architecture that fits the current repo over adding unnecessary abstractions.
- If the repo lacks a pattern for a concern, introduce the lightest maintainable solution.

Repository-specific guidance:
- Check `lib/main.dart` first to understand bootstrapping and the current main screen.
- Check `lib/ui/` and `lib/features/` before creating new folders.
- Check `test/unit_test/widget_test.dart`, `test/integration_test/app_test.dart`, and `integration_test/app_test.dart` before editing tests.
- Reuse existing Supabase initialization instead of creating a second app bootstrap path.
- If a feature needs persistence or network behavior that should be testable, add a small repository/service abstraction and inject it where appropriate.
- Keep file and class names consistent with existing naming in this repo.
- Don’t replace the current UI language/style unless explicitly requested.
- Preserve existing user changes if the git worktree is dirty.

Your task:
Implement the following feature fully in code.

Feature title:
[FEATURE TITLE]

GitHub issue / tracker reference:
[ISSUE NUMBER OR LINK]

User story:
As a [USER TYPE],
I want to [GOAL],
So that [OUTCOME].

Feature specification:
[PASTE THE FULL FEATURE DESCRIPTION HERE]

Screens affected:
- [SCREEN 1]
- [SCREEN 2]
- [SCREEN 3]

Functional requirements:
- [REQUIREMENT 1]
- [REQUIREMENT 2]
- [REQUIREMENT 3]

Behavior requirements:
- UI behavior: [DESCRIBE]
- Loading state: [DESCRIBE]
- Empty state: [DESCRIBE]
- Error state: [DESCRIBE]
- Validation: [DESCRIBE]
- Navigation behavior: [DESCRIBE]
- Authentication requirement: [YES/NO + DETAILS]
- Optimistic updates: [YES/NO + DETAILS]
- Offline behavior: [DESCRIBE OR N/A]

Data and backend requirements:
- Data source: [SUPABASE TABLE / API / LOCAL / NONE]
- Reads: [DESCRIBE]
- Writes: [DESCRIBE]
- Fields involved: [LIST]
- Failure handling: [DESCRIBE]
- Sync/cache expectations: [DESCRIBE]

Architecture expectations:
- Put business logic outside large widget trees when reasonable.
- Keep widgets focused and readable.
- Add brief comments only where logic is not obvious.
- Avoid introducing new packages unless truly necessary.
- Reuse existing components before creating new ones.
- If creating new files, place them in the most natural existing location.

Implementation steps you should follow:
1. Inspect the current implementation and identify integration points.
2. Explain the implementation plan briefly only after you understand the repo.
3. Implement the feature in code.
4. Update models, services/repositories, controllers/view models, and UI as needed.
5. Handle success and failure states properly.
6. Add tests for the core user interaction and critical edge cases.
7. Run formatting and tests if possible.
8. Summarize what changed, assumptions made, and how it was verified.

Definition of done:
- The feature works in the actual app flow.
- The UI reflects the expected behavior clearly.
- Data is persisted correctly if backend writes are required.
- Failure cases are handled gracefully.
- Tests cover the main behavior.
- The code fits the current repo instead of fighting it.

Constraints:
- Do not stop at analysis or pseudocode.
- Do not output only suggestions; make the code changes.
- If blocked, explain the blocker briefly and choose the smallest safe fallback.
- Keep the final summary concise and practical.

At the end, provide:
- Short summary of implementation
- Files changed
- Assumptions
- Verification performed
```

## Best-practice add-ons

If you want better results, append one or more of these sections to the prompt before sending it:

### For UI-heavy features

```text
UI notes:
- Keep the current visual language unless asked to redesign.
- Make mobile layout the priority.
- Ensure loading, disabled, and success states are visually obvious.
- Avoid placeholder UI unless explicitly approved.
```

### For Supabase-backed features

```text
Supabase notes:
- Use the existing Supabase client setup in the repo.
- Keep database access easy to mock in tests.
- Match exact table and field names from the specification.
- Handle network failures without leaving the UI in an invalid state.
```

Testing requirements (mandatory — do not skip):

Before writing any test, inspect:
- test/unit_test/widget_test.dart
- test/integration_test/app_test.dart
- integration_test/app_test.dart
Understand the existing mock setup, test helpers, and Supabase stub patterns. Reuse them.

Unit tests — required for every service/repository introduced:
- Test each public method independently.
- Mock Supabase client using the existing mock pattern in the repo (do not reinvent).
- Cover: happy path, network failure (SupabaseException), empty result, malformed data.
- Name tests as: `test('methodName: [scenario] → [expected outcome]', ...)`

Widget tests — required for every new screen or modified screen:
- Use `WidgetTester` to pump the widget under test.
- Inject fakes/stubs via constructor or provider — never hit real Supabase.
- Cover: loading state renders correctly, success state shows expected data,
  error state shows error message, empty state shows empty widget.
- Test user interactions: tap, form input, navigation trigger.
- Use `find.byType`, `find.text`, `find.byKey` — avoid brittle `find.byWidget`.

Integration tests — required if the feature crosses 2+ screens or involves auth:
- Follow the existing integration_test/app_test.dart structure.
- Use `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
- Stub Supabase at the HTTP layer or use the existing test Supabase project if configured.
- Cover the full user journey: enter screen → interact → verify final state.
- Include at least one failure journey (e.g., network down, invalid input).

Test file placement:
- Unit tests: test/unit_test/[feature_name]_test.dart
- Widget tests: test/unit_test/[screen_name]_widget_test.dart
- Integration tests: integration_test/[feature_name]_test.dart

After writing tests, run:
  flutter test test/unit_test/
  flutter test test/unit_test/ --coverage
  flutter test integration_test/ (if integration tests added)
Report the result. If a test fails, fix it before finalising.

Definition of done for tests:
- [ ] Unit tests pass for all new service/repository methods.
- [ ] Widget tests cover all 4 states: loading, success, error, empty.
- [ ] At least one user interaction is tested per new screen.
- [ ] Integration test covers the full happy path if feature spans multiple screens.
- [ ] No test uses real Supabase — all network calls are mocked or stubbed.
- [ ] flutter test passes with 0 failures.

Substituição do add-on ### For test-sensitive work
text### For test-sensitive work

Testing notes:
- Inspect existing test files first — understand mock/stub conventions before writing new ones.
- Unit test every public method on new services and repositories.
  Scenarios per method: happy path, empty result, network error, bad data.
- Widget test every new or modified screen for all 4 UI states:
  loading, success, error, empty.
- Integration test any feature that touches 2+ screens or requires auth.
- Use fakes injected via constructor or provider — never hit real Supabase in tests.
- Name tests descriptively: 'fetchAppointments: network error → returns Failure'.
- Run `flutter test --coverage` and report coverage for new files.
- Fix failing tests before summarising. Do not leave broken tests with a TODO.


## Recommended inputs before sending to an AI

Always prepare these six items first:

1. User story
2. Exact screens affected
3. Backend or storage changes
4. Success and failure behavior
5. Test expectations
6. Definition of done
