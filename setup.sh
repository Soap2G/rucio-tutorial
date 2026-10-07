#!/usr/bin/env bash
# Set up the terminal for the Rucio tutorial.
#
# Usage (in a SWAN terminal, from the repository folder):
#     source setup.sh <your-rucio-account>
#
# Your Rucio account is your IAM username.

RUCIO_STACK="${RUCIO_STACK:-/cvmfs/sw.escape.eu/rucio/41.1.1-rbac-7273054bfdc4}"

if [ -z "$1" ] && [ -z "$RUCIO_ACCOUNT" ]; then
    echo "Usage: source setup.sh <your-rucio-account>"
    return 1 2>/dev/null || exit 1
fi

if [ ! -f "$RUCIO_STACK/setup-tutorial.sh" ]; then
    echo "ERROR: $RUCIO_STACK is not available. Is CVMFS mounted? Ask the instructor."
    return 1 2>/dev/null || exit 1
fi

source "$RUCIO_STACK/setup-tutorial.sh" "${1:-$RUCIO_ACCOUNT}" || return 1

export ME="$RUCIO_ACCOUNT"   # short name used in the chapters
export TUTORIAL_HOME="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"
mkdir -p "$TUTORIAL_HOME/downloads"

if ! "$RUCIO_PYTHONBIN" -c "import gfal2" 2>/dev/null; then
    echo "NOTE: gfal2 is not available in this Python. 'rucio download' will not work: tell the instructor."
fi
