#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=../lib/core.sh
source "$INSTALL_DIR/lib/core.sh"

CURRENT_STAGE_NUM=01
stage_init 01 mirror
mirror_apply
print_timeshift_hint "01-mirror-ok"
stage_done "apt update 无报错" "grep -E 'URIs:|Suites:' /etc/apt/sources.list.d/ubuntu.sources"
