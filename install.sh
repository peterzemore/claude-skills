#!/usr/bin/env bash
# Install these skills into ~/.claude/skills/
# Usage: ./install.sh [--copy] [--uninstall]
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
DEST="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
MODE="link"

for arg in "$@"; do
  case "$arg" in
    --copy)      MODE="copy" ;;
    --uninstall) MODE="uninstall" ;;
    -h|--help)   sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

mkdir -p "$DEST"

for dir in "$SRC"/*/; do
  name="$(basename "$dir")"
  target="$DEST/$name"

  if [ "$MODE" = "uninstall" ]; then
    if [ -L "$target" ] || [ -d "$target" ]; then
      rm -rf "$target"
      echo "removed  $name"
    fi
    continue
  fi

  # Refuse to clobber a real directory we didn't create.
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "SKIP     $name (a non-symlink already exists at $target)" >&2
    continue
  fi

  rm -f "$target"
  if [ "$MODE" = "copy" ]; then
    cp -r "$dir" "$target"
    echo "copied   $name"
  else
    ln -s "${dir%/}" "$target"
    echo "linked   $name"
  fi
done

[ "$MODE" = "uninstall" ] || echo
[ "$MODE" = "uninstall" ] || echo "Skills usually load immediately; start a new session if they do not appear."
