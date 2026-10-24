#!/usr/bin/env bash
# Show what Grok posted since the last check. Run from the repo root.
set -euo pipefail

BRIDGE_DIR="${BRIDGE_DIR:-bridge}"
MARKER="$(git rev-parse --git-dir)/bridge_last_seen"

git pull --rebase --autostash --quiet

last="$(cat "$MARKER" 2>/dev/null || true)"
fmt='%h %ad %an | %s'

if [ -z "$last" ] || ! git cat-file -e "$last" 2>/dev/null; then
  echo "== First check: all bridge commits =="
  git log --format="$fmt" --date=format:'%Y-%m-%d %H:%M %z' -- "$BRIDGE_DIR"
  echo
  echo "== $BRIDGE_DIR/grok_to_claude.md =="
  cat "$BRIDGE_DIR/grok_to_claude.md" 2>/dev/null || echo "(none)"
else
  echo "== New bridge commits since ${last:0:7} =="
  git log --format="$fmt" --date=format:'%Y-%m-%d %H:%M %z' "$last"..HEAD -- "$BRIDGE_DIR"
  echo
  echo "== New lines in $BRIDGE_DIR/grok_to_claude.md =="
  git diff "$last"..HEAD -- "$BRIDGE_DIR/grok_to_claude.md" | sed -n 's/^+\([^+]\)/\1/p; s/^+$//p'
fi

echo
echo "== Current $BRIDGE_DIR/grok_status.json =="
cat "$BRIDGE_DIR/grok_status.json" 2>/dev/null || echo "(none)"

git rev-parse HEAD > "$MARKER"
