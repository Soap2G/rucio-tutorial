#!/usr/bin/env bash
# Step 3: generate the data, copy it to the source RSE directory on EOS, and register it.
# Run on a host with the EOS FUSE mount (e.g. lxplus) and write access to $EOS_BASE,
# with a Rucio root configuration and rucio-it-register installed.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/tutorial.env"

WORK="${WORK:-$HERE/work}"
STAGING="$WORK/staging"
DUMP="$WORK/dump.jsonl"
DEST="$EOS_BASE/$SOURCE_RSE"

echo "=== 3a. Generate data"
mkdir -p "$WORK"
python3 "$HERE/generate_data.py" --out "$STAGING" --eos-dir "$DEST" --dump "$DUMP"

echo "=== 3b. Copy to $DEST"
if [ ! -d "$DEST" ]; then
  echo "ERROR: $DEST is not visible. Use a host with the EOS FUSE mount." >&2
  exit 1
fi
rsync -a --checksum "$STAGING"/ "$DEST"/
echo "Copied $(find "$STAGING" -type f | wc -l) files"

echo "=== 3c. Register (dry run)"
rucio-it-register --rse-name "$SOURCE_RSE" --dump-file "$DUMP" --rule --batch-size 100 --dry-run

read -r -p "Dry run OK? Register for real [y/N] " answer
[ "$answer" = "y" ] || { echo "Stopped before registration."; exit 0; }

echo "=== 3d. Register"
rucio-it-register --rse-name "$SOURCE_RSE" --dump-file "$DUMP" --rule --batch-size 100

echo "=== Check"
rucio did list "$OPEN_SCOPE:*" --filter 'type=all' --short | head -20
rucio rule list --account root
