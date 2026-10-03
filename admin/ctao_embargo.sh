#!/usr/bin/env bash
# CTAO demonstrator: end (or restore) the proprietary period of one proposal. Run as root (the DMT).
#
#   ./ctao_embargo.sh end ctao-prop-b       # the data of proposal B becomes public
#   ./ctao_embargo.sh restore ctao-prop-b   # back to the start of the demo
#
# The end of the embargo is a property of the data, not of a person: the public role gets read on
# the proposal scope. Role expiry (expires_at) is per account, so it does not fit this case.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/ctao.env"

action="${1:-}"; scope="${2:-}"
case " $CTAO_PROPOSAL_SCOPES " in *" $scope "*) ;; *) echo "Usage: $0 end|restore <one of: $CTAO_PROPOSAL_SCOPES>" >&2; exit 1;; esac

case "$action" in
  end)     run rucio role permission add "$CTAO_PUBLIC_ROLE" read "$scope" ;;
  restore) run rucio role permission remove "$CTAO_PUBLIC_ROLE" read "$scope" ;;
  *)       echo "Usage: $0 end|restore <scope>" >&2; exit 1 ;;
esac

rucio role permission list "$CTAO_PUBLIC_ROLE"
