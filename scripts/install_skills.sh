#!/usr/bin/env bash
# install_skills.sh — link Orbit skills into ~/.cursor/skills
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="${ORBIT_SKILLS_DIR:-$HOME/.cursor/skills}"
MODE="${1:-link}" # link | copy

mkdir -p "$TARGET"

install_one() {
  local name="$1"
  local src="$REPO_ROOT/skill/$name"
  local dest="$TARGET/$name"
  if [[ ! -d "$src" ]]; then
    echo "Missing skill: $src" >&2
    exit 1
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    rm -rf "$dest"
  fi
  if [[ "$MODE" == "copy" ]]; then
    cp -R "$src" "$dest"
    echo "Copied $name → $dest"
  else
    ln -s "$src" "$dest"
    echo "Linked $name → $dest"
  fi
}

install_one orbit
install_one orbit-setup

# Ensure scripts executable
chmod +x "$REPO_ROOT"/skill/orbit/scripts/*.sh "$REPO_ROOT"/scripts/*.sh 2>/dev/null || true

echo "Done. In Cursor Agent run: orbit-setup   then   implement PROJ-123 (orbit skill)"
