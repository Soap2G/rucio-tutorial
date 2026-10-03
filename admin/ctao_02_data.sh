#!/usr/bin/env bash
# CTAO demonstrator, step 2: generate the data products, copy them to the source RSE, register them,
# close the observation datasets, and build the mixed "search result" dataset (case 4).
# Same host needs as 03_upload_register.sh (EOS FUSE mount, root config, rucio-it-register). DRY_RUN=1 supported.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/ctao.env"

WORK="${WORK:-$HERE/work-ctao}"
STAGING="$WORK/staging"
DUMP="$WORK/dump.jsonl"
DEST="$EOS_BASE/$SOURCE_RSE"

echo "=== Generate data"
mkdir -p "$WORK"
python3 "$HERE/generate_data.py" --set ctao --out "$STAGING" --eos-dir "$DEST" --dump "$DUMP"

echo "=== Copy to $DEST"
[ -d "$DEST" ] || { echo "ERROR: $DEST is not visible. Use a host with the EOS FUSE mount." >&2; exit 1; }
if [ "${DRY_RUN:-0}" = 1 ]; then
  rsync -a --checksum --dry-run --itemize-changes "$STAGING"/ "$DEST"/
else
  rsync -a --checksum "$STAGING"/ "$DEST"/
fi

echo "=== Register (dry run)"
rucio-it-register --rse-name "$SOURCE_RSE" --dump-file "$DUMP" --rule --batch-size 100 --dry-run
if [ "${DRY_RUN:-0}" != 1 ]; then
  read -r -p "Dry run OK? Register for real [y/N] " answer
  [ "$answer" = "y" ] || { echo "Stopped before registration."; exit 0; }
  rucio-it-register --rse-name "$SOURCE_RSE" --dump-file "$DUMP" --rule --batch-size 100
fi

echo "=== Close the observation datasets"
for f in $(cd "$STAGING" && ls -d ctao-prop-*/observations/obs-*); do
  scope="${f%%/*}"; name="${f#*/}/"
  run rucio did update --close "$scope:$name" || echo "      $scope:$name already closed"
  run rucio did metadata "$SET" "$scope:$name" --key datatype --value fits
done

echo "=== Search result that mixes proposals: $CTAO_SEARCH_DATASET"
# All of proposal A, one observation of B, all of public C.
files=$(cd "$STAGING" && find ctao-prop-a ctao-prop-b/observations/obs-0201 ctao-prop-c -type f | sort \
        | while read -r p; do echo "${p%%/*}:${p#*/}"; done)
if rucio did show "$CTAO_SEARCH_DATASET" > /dev/null 2>&1; then
  echo "SKIP  dataset exists"
else
  run rucio did add --type dataset "$CTAO_SEARCH_DATASET"
  # shellcheck disable=SC2086
  run rucio did content add --to-did "$CTAO_SEARCH_DATASET" $files
  run rucio did update --close "$CTAO_SEARCH_DATASET"
fi

[ "${DRY_RUN:-0}" = 1 ] && exit 0
echo "Check (as root, all files are visible)"
rucio did content list "$CTAO_SEARCH_DATASET"
