#!/usr/bin/env bash
# Step 1: create the tutorial RSEs, their protocol, attributes, distances, and unlimited quota for root and the account that runs the admin steps.
# Run as root (or an account with the admin attribute).
# Safe to run again: a missing RSE is created, and an existing RSE is completed (attributes, protocol, limit).
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/tutorial.env"

DOMAINS='{"lan": {"read": 1, "write": 1, "delete": 1}, "wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy_read": 1, "third_party_copy_write": 1}}'

for spec in $RSES; do
  IFS=: read -r rse country site type <<< "$spec"

  if rucio rse show "$rse" > /dev/null 2>&1; then
    echo "OK    $rse exists; checking its settings"
    exists=1
  else
    echo "ADD   $rse ($country, $site, $type)"
    run rucio rse add "$rse"
    exists=0
  fi

  run rucio rse update "$rse" --key rse_type --value DISK
  run rucio rse attribute "$SET" "$rse" --key lfn2pfn_algorithm --value identity
  run rucio rse attribute "$SET" "$rse" --key fts --value "$FTS"
  run rucio rse attribute "$SET" "$rse" --key country --value "$country"
  run rucio rse attribute "$SET" "$rse" --key site --value "$site"
  run rucio rse attribute "$SET" "$rse" --key type --value "$type"

  if [ "$exists" = 1 ] && rucio rse show "$rse" 2>/dev/null | has "$EOS_HOST"; then
    echo "      protocol exists"
  else
    run rucio rse protocol add "$rse" \
      "$HOSTNAME_OPT" "$EOS_HOST" --scheme https --port "$EOS_PORT" \
      --prefix "/$EOS_BASE/$rse" \
      --impl rucio.rse.protocols.gfal.Default \
      --domain-json "$DOMAINS"
  fi

  # The admin rules (steps 3 and 4) belong to the account that runs them: root, or your admin account.
  for owner in root ${TUTORIAL_ACCOUNT:-}; do
    run rucio account limit "$SET" "$owner" --rse "$rse" --bytes infinity
  done
done

echo "Distances (all pairs, 1)"
for src in $(rse_names); do
  for dst in $(rse_names); do
    [ "$src" = "$dst" ] && continue
    run rucio rse distance "$SET" "$src" "$dst" --distance 1 2>/dev/null \
      || echo "      distance $src -> $dst not set (it exists already, or an RSE is missing)"
  done
done

[ "${DRY_RUN:-0}" = 1 ] && exit 0

echo "Check"
for rse in $(rse_names); do
  echo "--- $rse"
  rucio rse attribute list "$rse"
done
rucio rse list --rses 'country=IT'
