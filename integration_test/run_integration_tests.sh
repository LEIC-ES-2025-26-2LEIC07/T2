#!/usr/bin/env bash
set -euo pipefail

# Run from project root regardless of where the script is invoked from
cd "$(dirname "${BASH_SOURCE[0]}")/.."

DEVICE="${1:-linux}"
TESTS=(
  integration_test/app_test.dart
  integration_test/calendar_journey_test.dart
  integration_test/edit_medication_journey_test.dart
  integration_test/symptom_log_journey_test.dart
  integration_test/profile_update_flow_test.dart
  integration_test/add_medication_journey_test.dart
  integration_test/edit_delete_medication_journey_test.dart
  integration_test/missed_medication_journey_test.dart
  integration_test/register_flow_test.dart
  integration_test/notification_flow_test.dart
  integration_test/notification_delivery_test.dart
)

PASS=0; FAIL=0

for t in "${TESTS[@]}"; do
  echo "▶ $t"
  if flutter test "$t" -d "$DEVICE"; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
  fi
  sleep 2
done

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ $FAIL -eq 0 ]
