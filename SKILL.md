---
name: npm-quarantine
description: Install a rolling time-window quarantine for npm installs to protect against supply chain attacks. Wraps the npm command so that only package versions published at least N days ago can be installed — giving the community time to detect malicious releases before they land on your machine. Use this skill when the user mentions npm supply chain security, package quarantine, install safety, time-gated installs, protecting against compromised npm packages, or wants to lock down npm against recent malicious publishes. Also use when users mention attacks like Shai-Hulud, TanStack compromise, or any npm worm incident.
---

# npm-quarantine

A lightweight npm wrapper that enforces a rolling time window on package installs. If a package version was published less than N days ago, npm refuses to install it. This gives the open-source community time to detect and flag compromised releases before they reach your machine.

This works by leveraging npm's built-in `--before` flag. A wrapper script named `npm` is placed early in PATH so that every caller — interactive shells, CI, and AI coding agents — gets the protection automatically.

## How it works

npm supports `--before=<date>` which tells the resolver to pretend versions published after that date don't exist. The wrapper computes `now - N days` dynamically on every invocation and injects `--before` into install/add/update commands. All other npm commands pass through untouched.

## Installation steps

### 1. Create the wrapper script

Detect the OS and choose the right install path:

- **Linux**: `~/.local/bin/npm`
- **macOS**: `~/.local/bin/npm`

Both use the same script — the only OS difference is the `date` command syntax.

Create `~/.local/bin/npm` with this content:

```bash
#!/usr/bin/env bash
# npm-quarantine: rolling time-window protection against supply chain attacks
# Refuses to install package versions published in the last N days.
# Override: NPM_QUARANTINE_DAYS=7 npm install <pkg>
# Bypass:   command npm install <pkg>  (or use full path to real npm)

QUARANTINE_DAYS="${NPM_QUARANTINE_DAYS:-14}"

# Cross-platform date: macOS uses -v, Linux uses -d
if [[ "$(uname)" == "Darwin" ]]; then
  BEFORE_DATE="$(date -u -v-${QUARANTINE_DAYS}d +%Y-%m-%dT%H:%M:%SZ)"
else
  BEFORE_DATE="$(date -u -d "${QUARANTINE_DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ)"
fi

# Find the real npm binary (skip this wrapper)
REAL_NPM=""
while IFS= read -r candidate; do
  [[ "$candidate" != "$0" && "$candidate" != "$(realpath "$0" 2>/dev/null)" ]] && REAL_NPM="$candidate" && break
done < <(which -a npm 2>/dev/null)
REAL_NPM="${REAL_NPM:-/usr/bin/npm}"

# Only inject --before for commands that resolve packages from the registry
INSTALL_CMDS="install|i|add|ci|update|upgrade"
CMD="${1:-}"

if [[ "$CMD" =~ ^($INSTALL_CMDS)$ ]]; then
  echo "🛡️  npm-quarantine: only versions published before ${BEFORE_DATE} (${QUARANTINE_DAYS}-day window)" >&2
  exec "$REAL_NPM" "$@" --before="$BEFORE_DATE"
else
  exec "$REAL_NPM" "$@"
fi
```

### 2. Make it executable and ensure PATH order

```bash
chmod +x ~/.local/bin/npm
```

Then ensure `~/.local/bin` is at the front of PATH in the appropriate shell profile:

- **bash** (`~/.bashrc` and `~/.profile`): `export PATH="$HOME/.local/bin:$PATH"`
- **zsh** (`~/.zshrc`): `export PATH="$HOME/.local/bin:$PATH"`

Add the export to **both** the interactive RC file and the login profile so it applies to AI agents and non-interactive shells too.

### 3. Verify

Run this to confirm the wrapper intercepts npm:

```bash
which npm  # should show ~/.local/bin/npm
npm install --dry-run 2>&1 | head -1  # should show the 🛡️ quarantine message
```

## After installation

Tell the user:

- **Default window**: 14 days (change with `NPM_QUARANTINE_DAYS=7 npm install ...`)
- **Bypass**: Use the real npm directly, e.g. `/usr/bin/npm install <pkg>` or `command npm install <pkg>`
- **Scope**: Protects `install`, `i`, `add`, `ci`, `update`, `upgrade` commands. All others pass through normally.
- **Bun note**: Bun has no `--before` equivalent. If the user uses Bun for installs, this won't cover those. Suggest using npm for dependency installs where supply chain safety matters.

## Uninstall

Simply `rm ~/.local/bin/npm`. The real npm at `/usr/bin/npm` (or wherever it lives) takes over immediately.
