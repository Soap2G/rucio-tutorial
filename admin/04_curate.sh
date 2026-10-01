#!/usr/bin/env bash
# Step 4: close the datasets, add metadata, and make a second copy of the climate data on the archive RSE.
# Run as root after step 3. Safe to run again.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/tutorial.env"

# One dataset per line: did|datatype|description
DATASETS="$OPEN_SCOPE:climate/station-trieste-2025/|csv|Hourly temperature and humidity, Trieste station, 2025
$OPEN_SCOPE:climate/station-geneva-2025/|csv|Hourly temperature and humidity, Geneva station, 2025
$OPEN_SCOPE:imaging/microscopy-batch-01/|png|Synthetic fluorescence microscopy images, batch 01
$OPEN_SCOPE:humanities/archive-catalogue/|json|Catalogue records of a historical archive
$OPEN_SCOPE:instrument/raw-run-001/|bin|Raw instrument output, run 001 (large files)
$EMBARGO_SCOPE:survey/wave-2026/|csv|Pseudonymised survey responses, wave 2026 (embargoed)"

while IFS='|' read -r did datatype description; do
  echo "--- $did"
  rucio did update --close "$did" || echo "      already closed"
  rucio did metadata set "$did" --key datatype --value "$datatype"
  # Custom keys need a JSON metadata plugin on the server; the tutorial does not depend on them.
  rucio did metadata set "$did" --key description --value "$description" 2>/dev/null \
    || echo "      custom metadata key not supported by the server (OK)"
done <<< "$DATASETS"

echo "=== Second copy of the climate data on $ARCHIVE_RSE (FTS transfer)"
if rucio rule list --did "$OPEN_SCOPE:climate" | grep -q "$ARCHIVE_RSE"; then
  echo "SKIP  rule exists"
else
  rucio rule add "$OPEN_SCOPE:climate" --copies 1 --rses "$ARCHIVE_RSE" \
    --comment "Tutorial: preservation copy of the climate data"
fi
rucio rule list --did "$OPEN_SCOPE:climate"
