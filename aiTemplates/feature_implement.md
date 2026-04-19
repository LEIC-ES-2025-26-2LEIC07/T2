You are a senior Flutter engineer working directly in my existing repository.
Your job in this pass: implement the feature only. Do not write tests.

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
- Reuse existing Supabase initialization instead of creating a second app bootstrap path.
- If a feature needs persistence or network behavior that should be testable,
  add a small repository/service abstraction and inject it where appropriate.
- Keep file and class names consistent with existing naming in this repo.
- Don't replace the current UI language/style unless explicitly requested.
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
- Every new service or repository must be injectable (constructor injection preferred)
  so the test pass can mock it without modifying the implementation.

Implementation steps:
1. Inspect the current implementation and identify integration points.
2. Explain the implementation plan briefly only after you understand the repo.
3. Implement the feature in code.
4. Update models, services/repositories, controllers/view models, and UI as needed.
5. Handle success and failure states properly.
6. Run flutter format and flutter analyze. Fix all warnings before finishing.
7. Do NOT write tests. Leave that for the test pass.

Definition of done:
- The feature works in the actual app flow.
- The UI reflects the expected behavior clearly.
- Data is persisted correctly if backend writes are required.
- Failure cases are handled gracefully.
- flutter analyze returns no errors or warnings.
- The code fits the current repo instead of fighting it.

Constraints:
- Do not stop at analysis or pseudocode.
- Do not output only suggestions; make the code changes.
- If blocked, explain the blocker briefly and choose the smallest safe fallback.
- Do NOT write any test files in this pass.

At the end, output this exact block (the test pass will consume it):

FEATURE_SUMMARY:
- Files created: [list every new file with its full path]
- Files modified: [list every modified file with its full path]
- New public classes: [list class name + file]
- New public methods: [list method name + class + file]
- Supabase tables touched: [list table names]
- Supabase fields touched: [list field names per table]
- Injectable dependencies: [list class name + how it is injected]
- Known gaps or assumptions: [list anything the test pass should know]