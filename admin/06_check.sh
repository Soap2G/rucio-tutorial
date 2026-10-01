#!/usr/bin/env bash
# Step 6: readiness check before the course. Read-only. Run as root.
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/tutorial.env"

fail=0
check () {  # check "<description>" <command...>
  local what="$1"; shift
  if "$@" > /dev/null 2>&1; then echo "OK    $what"; else echo "FAIL  $what"; fail=$((fail + 1)); fi
}

check "server reachable" rucio ping
for rse in $(rse_names); do
  check "RSE $rse" rucio rse show "$rse"
done
check "RSE expression country=IT gives 2 RSEs" \
  bash -c "[ \$(rucio rse list --rses 'country=IT' | grep -c _) -eq 2 ]"

for scope in "$OPEN_SCOPE" "$EMBARGO_SCOPE"; do
  check "scope $scope has datasets" bash -c "rucio did list '$scope:*' --short | grep -q /"
done
check "role $STUDENT_ROLE"  bash -c "rucio role list | grep -qw $STUDENT_ROLE"
check "role $EMBARGO_ROLE"  bash -c "rucio role list | grep -qw $EMBARGO_ROLE"

check "no rule of root is STUCK or REPLICATING" \
  bash -c "! rucio rule list --account root | grep -E 'STUCK|REPLICATING'"

# Students download anonymously over HTTPS: the storage must answer without a credential.
sample="https://$EOS_HOST:$EOS_PORT/$EOS_BASE/$SOURCE_RSE/$OPEN_SCOPE/climate/station-trieste-2025/trieste-2025-01.csv"
check "anonymous HTTPS read of a sample file" curl -sfI -k "$sample"   # availability only, -k: CA trust is not tested here
check "archive copy exists on $ARCHIVE_RSE" \
  bash -c "rucio replica list dataset '$OPEN_SCOPE:climate/station-trieste-2025/' | grep -q $ARCHIVE_RSE"

echo "Failures: $fail"
exit "$fail"
