#!/usr/bin/env bash
# Step 5: prepare each student account: personal scope, quota on every RSE, role check.
# Run as root after the IAM sync has created the accounts. Safe to run again.
# Input: students.txt, one Rucio account per line (# comments allowed).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/tutorial.env"

[ -f "$STUDENTS_FILE" ] || { echo "ERROR: $STUDENTS_FILE not found (see students.txt.example)" >&2; exit 1; }

problems=0
while read -r account _; do
  [[ -z "$account" || "$account" == \#* ]] && continue
  echo "--- $account"

  if ! rucio account show "$account" > /dev/null 2>&1; then
    echo "      MISSING account (not in IAM group data-management, or the sync has not run yet)"
    problems=$((problems + 1))
    continue
  fi

  # Personal scope. If iamSync.userScopes is on, the sync has made it already.
  if rucio scope list --account "$account" | has -w "$account"; then
    echo "      scope OK"
  else
    run rucio scope add "$account" --account "$account" && echo "      scope ADDED"
  fi

  for rse in $(rse_names); do
    run rucio account limit "$SET" "$account" --rse "$rse" --bytes "$STUDENT_QUOTA" > /dev/null
  done
  echo "      quota $STUDENT_QUOTA on $(rse_names | wc -l | tr -d " ") RSEs"

  if rucio role account list --account "$account" | has -w "$STUDENT_ROLE"; then
    echo "      role $STUDENT_ROLE OK"
  else
    echo "      role $STUDENT_ROLE MISSING (add the user to IAM data-management/roles/$STUDENT_ROLE)"
    problems=$((problems + 1))
  fi
done < "$STUDENTS_FILE"

echo "Problems: $problems"
[ "$problems" -eq 0 ]
