# Bug Report — Sprint 3

## BUG-001 · Add Medication fails silently on submission

| Field | Value |
|---|---|
| **Date found** | 2026-05-17 |
| **Severity** | High — core feature broken |
| **Status** | Resolved |
| **Branch** | `111-add-medication-screen-refac` |
| **Reported by** | David (senior dev) |
| **Fixed by** | David + Claude Code (AI-assisted) |

---

### Description

Submitting the Add Medication form caused a silent failure. The loading spinner appeared but the medication was never saved to the database. No user-facing error was shown in most cases; when it was, the message was generic.

### Steps to Reproduce

1. Open the app and log in.
2. Navigate to the Medications tab.
3. Tap "Add Medication".
4. Fill in a name (e.g. "Aspirin") and a dosage with units (e.g. "100mg").
5. Tap Save.
6. Observe: no medication is added; the form may show a generic error or reset silently.

### Root Cause

The `dosage` column in the Supabase `medications` table had type `INTEGER`. The Flutter codebase sends dosage as a `String` (e.g. `"100mg"`, `"500mg"`) since dosage values include unit suffixes. This type mismatch caused Postgres to reject every insert with error code `22P02`:

```
PostgrestException:
  code   : 22P02
  message: invalid input syntax for type integer: "100mg"
  details: Bad Request
```

The existing unit test suite did not catch this because all repository tests use mocked Supabase clients — they verify Dart logic but never touch the real database.

### Why It Wasn't Caught Earlier

- All `SupabaseMedicationRepository` tests use `FakeQueryBuilder` / `FakeFilterBuilder` mocks.
- Schema constraints (column types, RLS policies) are invisible to mocked tests.
- The `dosage` column type was changed at some point without a corresponding Dart model or migration review.

### How It Was Diagnosed

A step-by-step integration test was written (`test/features/medication/data/add_medication_integration_test.dart`) that hits the real Supabase database:

| Step | What it tests |
|---|---|
| 1 | Sign-in → `currentUser != null` |
| 2 | Raw INSERT into `medications` table |
| 3 | Raw INSERT into `medication_reminders` table |
| 4 | Full `SupabaseMedicationRepository.addMedication()` flow |

Step 2 failed immediately with `22P02`, pinpointing the `dosage` column as the cause.

Run the test with:

```bash
flutter test test/features/medication/data/add_medication_integration_test.dart \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<anon_key> \
  --dart-define=TEST_EMAIL=<email> \
  --dart-define=TEST_PASSWORD=<password>
```

### Fix Applied

No Dart code changes were needed — the model was correct. The fix was a schema migration on the Supabase side:

```sql
ALTER TABLE medications ALTER COLUMN dosage TYPE text;
```

Executed via the Supabase SQL Editor on 2026-05-17.

### Verification

After applying the migration, re-run the integration test. All 4 steps should pass. The Add Medication form should now save successfully end-to-end.

### Lessons Learned

- **Mocked tests cannot catch schema drift.** Integration tests against the real DB are necessary for any operation that depends on column types, RLS policies, or DB constraints.
- **`PostgrestException.code` is the fastest diagnostic signal.** Code `22P02` immediately identifies a type mismatch without needing to open the Supabase dashboard.
- **Schema changes must be reviewed alongside Dart model changes.** Changing a column type is a breaking change for the client if the Dart field type doesn't match.
