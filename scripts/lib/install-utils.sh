#!/usr/bin/env bash

# Shared helpers for package installation commands that may fail due to conflicts.
# Behavior on failure (interactive): retry, retry without --noconfirm, skip, or abort.

is_interactive_tty() {
  [[ -t 0 || -r /dev/tty ]]
}

tty_echo() {
  if [[ -w /dev/tty ]]; then
    echo "$*" > /dev/tty
  else
    echo "$*"
  fi
}

tty_read_choice() {
  local prompt="$1"
  local answer=""
  if [[ -r /dev/tty ]]; then
    read -r -p "${prompt}" answer < /dev/tty || true
  else
    read -r -p "${prompt}" answer || true
  fi
  printf '%s' "${answer}"
}

strip_noconfirm_flag() {
  local arg
  for arg in "$@"; do
    [[ "${arg}" == "--noconfirm" ]] && continue
    printf '%s\n' "${arg}"
  done
}

run_with_install_prompt() {
  local label="$1"
  shift
  local -a cmd=("$@")

  while true; do
    if "${cmd[@]}"; then
      return 0
    fi

    tty_echo "Command failed while installing: ${label}"

    if ! is_interactive_tty; then
      echo "Non-interactive shell: cannot prompt for conflict resolution." >&2
      return 1
    fi

    tty_echo "Choose action: [r]etry, [i]nteractive retry, [s]kip, [a]bort"
    choice="$(tty_read_choice "> ")"
    case "${choice:-a}" in
      r|R)
        continue
        ;;
      i|I)
        mapfile -t interactive_cmd < <(strip_noconfirm_flag "${cmd[@]}")
        if "${interactive_cmd[@]}"; then
          return 0
        fi
        ;;
      s|S)
        echo "Skipping: ${label}"
        return 0
        ;;
      a|A)
        return 1
        ;;
      *)
        tty_echo "Please choose r, i, s, or a."
        ;;
    esac
  done
}

pacman_install_prompt() {
  local label="$1"
  shift
  run_with_install_prompt "${label}" sudo pacman -S --needed --noconfirm "$@"
}

pacman_upgrade_prompt() {
  local label="${1:-system upgrade}"
  run_with_install_prompt "${label}" sudo pacman -Syu --noconfirm
}

paru_install_prompt() {
  local label="$1"
  shift
  run_with_install_prompt "${label}" paru -S --needed --noconfirm "$@"
}
