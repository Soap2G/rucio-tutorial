#!/usr/bin/env bash
# Step 1: create the tutorial RSEs, their protocol, attributes, distances and root limits.
# Run as root (or an account with the admin attribute). Safe to run again: an existing RSE is left as it is.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/tutorial.env"

DOMAINS='{"lan": {"read": 1, "write": 1, "delete": 1}, "wan": {"read": 1, "write": 1, "delete": 1, "third_party_copy_read": 1, "third_party_copy_write": 1}}'

for spec in $RSES; do
  IFS=: read -r rse country site type <<< "$spec"

  if rucio rse show "$rse" > /dev/null 2>&1; then
    echo "SKIP  $rse exists"
    continue
  fi

  echo "ADD   $rse ($country, $site, $type)"
  run rucio rse add "$rse"
  run rucio rse update "$rse" --key rse_type --value DISK
  run rucio rse attribute set "$rse" --key lfn2pfn_algorithm --value identity
  run rucio rse attribute set "$rse" --key fts --value "$FTS"
  run rucio rse attribute set "$rse" --key country --value "$country"
  run rucio rse attribute set "$rse" --key site --value "$site"
  run rucio rse attribute set "$rse" --key type --value "$type"

  run rucio rse protocol add "$rse" \
    --hostname "$EOS_HOST" --scheme https --port "$EOS_PORT" \
    --prefix "/$EOS_BASE/$rse" \
    --impl rucio.rse.protocols.gfal.Default \
    --domain-json "$DOMAINS"

  run rucio account limit set root --rse "$rse" --bytes infinity
done

echo "Distances (all pairs, 1)"
for src in $(rse_names); do
  for dst in $(rse_names); do
    [ "$src" = "$dst" ] && continue
    run rucio rse distance set "$src" "$dst" --distance 1 2>/dev/null \
      || echo "      distance $src -> $dst exists"
  done
done

echo "Check"
for rse in $(rse_names); do
  echo "--- $rse"
  rucio rse attribute list "$rse"
done
rucio rse list --rses 'country=IT'
