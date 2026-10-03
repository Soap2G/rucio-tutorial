#!/usr/bin/env bash
# CTAO demonstrator, step 1: proposal scopes, catalogue scope and roles.
# Needs the RBAC client (rucio role ...). Run as root. Safe to run again. DRY_RUN=1 supported.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/ctao.env"

for scope in $CTAO_PROPOSAL_SCOPES "$CTAO_CATALOGUE_SCOPE"; do
  if rucio scope list --account "$SCOPE_OWNER" | has -w "$scope"; then
    echo "SKIP  scope $scope exists"
  else
    echo "ADD   scope $scope (owner $SCOPE_OWNER)"
    run rucio scope add "$scope" --account "$SCOPE_OWNER"
  fi
done

role_exists () { rucio role list | has -w "$1"; }

# One assignable, locked role per proposal group: read on its proposal scope.
for scope in $CTAO_PROPOSAL_SCOPES; do
  role="$(proposal_role "$scope")"
  if role_exists "$role"; then echo "SKIP  role $role exists"; continue; fi
  echo "ADD   role $role (read on $scope)"
  run rucio role add "$role" --assignable true --locked false \
    --description "CTAO proposal group of $scope (PI, co-PI, co-Is). Synced from IAM data-management/roles/$role."
  run rucio role permission add "$role" read "$scope"
  run rucio role update "$role" --locked true
done

# The public role: read on the catalogue and on every proposal whose proprietary period is over.
if role_exists "$CTAO_PUBLIC_ROLE"; then
  echo "SKIP  role $CTAO_PUBLIC_ROLE exists"
else
  echo "ADD   role $CTAO_PUBLIC_ROLE"
  run rucio role add "$CTAO_PUBLIC_ROLE" --assignable true --locked false \
    --description "Any scientist with a CTAO account: public data. Synced from IAM data-management/roles/$CTAO_PUBLIC_ROLE."
  run rucio role permission add "$CTAO_PUBLIC_ROLE" read "$CTAO_CATALOGUE_SCOPE"
  for scope in $CTAO_PUBLIC_AT_START; do
    run rucio role permission add "$CTAO_PUBLIC_ROLE" read "$scope"
  done
fi

[ "${DRY_RUN:-0}" = 1 ] && exit 0
echo "Check"
rucio role list --detail | grep -E "ctao|Role|---" || true
