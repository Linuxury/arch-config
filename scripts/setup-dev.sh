#!/usr/bin/env bash
set -euo pipefail

# Install Python + Rust development baseline.

if ! command -v pacman >/dev/null 2>&1; then
  echo "This script must run on an Arch-based system with pacman." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/install-utils.sh"

pacman_install_prompt "development bundle" \
  python python-pip python-virtualenv python-pipx uv \
  rustup \
  base-devel pkgconf cmake clang lldb

pipx ensurepath || true

if command -v rustup >/dev/null 2>&1; then
  rustup toolchain install stable
  rustup default stable
  rustup component add rustfmt clippy rust-analyzer
fi

echo "Dev stack installed (Python + Rust)."
echo "Python quick start: uv init myproj"
echo "Rust quick start: cargo new hello-rust"
