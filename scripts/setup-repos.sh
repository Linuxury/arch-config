#!/usr/bin/env bash
set -euo pipefail

# Repository/AUR layer.
# Env toggles:
#   USE_CHAOTIC=1 INSTALL_PARU=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USE_CHAOTIC="${USE_CHAOTIC:-1}"
INSTALL_PARU="${INSTALL_PARU:-1}"

if [[ "${USE_CHAOTIC}" == "1" && -x "${SCRIPT_DIR}/setup-chaotic-aur.sh" ]]; then
  "${SCRIPT_DIR}/setup-chaotic-aur.sh"
fi

if [[ "${INSTALL_PARU}" == "1" && -x "${SCRIPT_DIR}/setup-paru.sh" ]]; then
  "${SCRIPT_DIR}/setup-paru.sh"
fi
