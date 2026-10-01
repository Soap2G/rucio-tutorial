#!/usr/bin/env bash
# Chapter 4: give or end the embargo role for all students. Run as root during the course.
#
#   ./embargo_access.sh grant [minutes]   # default 15 minutes
#   ./embargo_access.sh end               # end it now (if the course runs late)
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/tutorial.env"

action="${1:-}"
minutes="${2:-15}"

students () { grep -v -e '^\s*#' -e '^\s*$' "$STUDENTS_FILE" | awk '{print $1}'; }

case "$action" in
  grant)
    # expires_at is stored in UTC
    expires="$(python3 -c "import datetime as d; print((d.datetime.now(d.timezone.utc) + d.timedelta(minutes=$minutes)).strftime('%Y-%m-%dT%H:%M:%S'))")"
    echo "Grant $EMBARGO_ROLE until $expires UTC"
    for a in $(students); do
      run rucio role account add "$EMBARGO_ROLE" "$a" --expires-at "$expires" --force \
        || run rucio role account update "$EMBARGO_ROLE" "$a" --expires-at "$expires"
      echo "  $a"
    done
    ;;
  end)
    echo "Remove $EMBARGO_ROLE now"
    for a in $(students); do
      run rucio role account remove "$EMBARGO_ROLE" "$a" --force && echo "  $a"
    done
    ;;
  *)
    echo "Usage: $0 grant [minutes] | end" >&2
    exit 1
    ;;
esac

rucio role account list --role "$EMBARGO_ROLE"
