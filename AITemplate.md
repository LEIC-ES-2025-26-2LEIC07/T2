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

### For test-sensitive work

```text
Testing notes:
- Update existing tests instead of duplicating coverage when possible.
- Add widget tests for user interaction.
- Add or adjust integration coverage if the repo pattern supports it.
- Cover both happy path and failure path.
```

## Copy-paste quick version

```text
Act as a senior Flutter engineer inside my existing `T2` repo for ClinicGO. Inspect the current codebase first, especially `lib/main.dart`, `lib/ui/`, `lib/features/`, and existing tests. Then implement this feature end-to-end in the real app using the current architecture and style. Reuse current patterns, keep changes minimal and production-ready, handle loading/success/failure states, add tests, run format/tests if possible, and finish with a concise summary of changes, assumptions, and verification.

Feature:
[PASTE FEATURE HERE]

Requirements:
- [REQ 1]
- [REQ 2]
- [REQ 3]

Constraints:
- Don’t refactor unrelated areas
- Don’t stop at analysis
- Keep the solution testable
- Include edge-case handling
```

## Recommended inputs before sending to an AI

Always prepare these six items first:

1. User story
2. Exact screens affected
3. Backend or storage changes
4. Success and failure behavior
5. Test expectations
6. Definition of done
