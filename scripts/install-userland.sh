#!/usr/bin/env bash
set -euo pipefail

# Userland layer (apps, dev, gaming, COSMIC packages).
# Env toggles:
#   INSTALL_APPS=1 INSTALL_DEV=1 INSTALL_GAMING=1 INSTALL_COSMIC=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_APPS="${INSTALL_APPS:-1}"
INSTALL_DEV="${INSTALL_DEV:-1}"
INSTALL_GAMING="${INSTALL_GAMING:-1}"
INSTALL_COSMIC="${INSTALL_COSMIC:-1}"

if [[ "${INSTALL_APPS}" == "1" && -x "${SCRIPT_DIR}/setup-apps.sh" ]]; then
  "${SCRIPT_DIR}/setup-apps.sh"
fi

if [[ "${INSTALL_DEV}" == "1" && -x "${SCRIPT_DIR}/setup-dev.sh" ]]; then
  "${SCRIPT_DIR}/setup-dev.sh"
fi

if [[ "${INSTALL_GAMING}" == "1" && -x "${SCRIPT_DIR}/setup-gaming.sh" ]]; then
  "${SCRIPT_DIR}/setup-gaming.sh"
fi

if [[ "${INSTALL_COSMIC}" == "1" && -x "${SCRIPT_DIR}/setup-cosmic.sh" ]]; then
  "${SCRIPT_DIR}/setup-cosmic.sh"
fi
