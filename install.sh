#!/usr/bin/env bash
set -e

DEST="$HOME/.local/bin"
mkdir -p "$DEST"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/npm-quarantine" ]]; then
  cp "$SCRIPT_DIR/npm-quarantine" "$DEST/npm"
else
  curl -fsSL https://raw.githubusercontent.com/maximus-cx-solutions-ai/npm-quarantine/main/npm-quarantine -o "$DEST/npm"
fi
chmod +x "$DEST/npm"

# Ensure PATH
add_to_profile() {
  local file="$1"
  [[ -f "$file" ]] || return
  grep -q '\.local/bin' "$file" 2>/dev/null && return
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$file"
  echo "  Updated $file"
}

echo "Installed npm-quarantine to $DEST/npm"

SHELL_NAME="$(basename "$SHELL")"
case "$SHELL_NAME" in
  zsh)  add_to_profile "$HOME/.zshrc" ;;
  bash) add_to_profile "$HOME/.bashrc"; add_to_profile "$HOME/.profile" ;;
  *)    add_to_profile "$HOME/.profile" ;;
esac

echo ""
echo "🛡️  npm-quarantine active (14-day default window)"
echo "   Restart your shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
