#!/usr/bin/env bash
# Step 2: create the shared scopes and the two tutorial roles.
# Needs the RBAC client (rucio role ...). Run as root. Safe to run again.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/tutorial.env"

for scope in "$OPEN_SCOPE" "$EMBARGO_SCOPE"; do
  if rucio scope list --account "$SCOPE_OWNER" | has -w "$scope"; then
    echo "SKIP  scope $scope exists"
  else
    echo "ADD   scope $scope (owner $SCOPE_OWNER)"
    run rucio scope add "$scope" --account "$SCOPE_OWNER"
  fi
done

# A role is created unlocked, gets its permission, then is locked.
# Locked = nobody changes its permissions or deletes it by mistake during the course.
add_role () {
  local name="$1" assignable="$2" scope="$3" description="$4"
  if rucio role list | has -w "$name"; then
    echo "SKIP  role $name exists"
    return
  fi
  echo "ADD   role $name (assignable=$assignable, read on $scope)"
  run rucio role add "$name" --description "$description" --assignable "$assignable" --locked false
  run rucio role permission add "$name" read "$scope"
  run rucio role update "$name" --locked true
}

add_role "$STUDENT_ROLE" true  "$OPEN_SCOPE" \
  "Tutorial student: read the shared open data. Synced from IAM data-management/roles/$STUDENT_ROLE."
add_role "$EMBARGO_ROLE" false "$EMBARGO_SCOPE" \
  "Read the embargoed data. Granted by an admin only, with an expiry date."

echo "Check"
rucio role list --detail
