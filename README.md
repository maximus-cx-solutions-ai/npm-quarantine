# npm-quarantine

A lightweight npm wrapper that enforces a rolling time window on package installs. If a package version was published less than N days ago, npm refuses to install it — giving the community time to detect malicious releases before they reach your machine.

Built in response to the [TanStack supply chain attack](https://snyk.io/blog/tanstack-npm-packages-compromised/) (May 11, 2026).

## How it works

npm supports `--before=<date>` which tells the resolver to ignore versions published after that date. This wrapper computes `now - N days` dynamically and injects `--before` into install commands. Everything else passes through untouched.

## Install

```bash
mkdir -p ~/.local/bin

curl -fsSL https://raw.githubusercontent.com/maximus-cx-solutions-ai/npm-quarantine/main/install.sh | bash
```

Or manually:

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/maximus-cx-solutions-ai/npm-quarantine/main/npm-quarantine -o ~/.local/bin/npm
chmod +x ~/.local/bin/npm

# Add to your shell profile (~/.bashrc, ~/.zshrc, ~/.profile):
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```bash
# Works automatically — just use npm as normal
npm install lodash   # only versions published 14+ days ago

# Override the window
NPM_QUARANTINE_DAYS=7 npm install lodash

# Bypass entirely
/usr/bin/npm install lodash
# or
command npm install lodash
```

## Demo

```
$ npm install eslint --dry-run
🛡️  npm-quarantine: only versions published before 2026-04-28T11:30:09Z (14-day window)
add eslint 10.2.1      # ← 10.3.0 (May 1) blocked, falls back to 10.2.1 (Apr 17)
```

## Why

On May 11, 2026, 84 malicious npm packages were published under the `@tanstack` namespace via a compromised CI pipeline. The worm spread to 170+ packages including `@mistralai` and `@uipath`. A 14-day quarantine window would have blocked every one of those installs.

## Works for AI agents too

The wrapper is placed at `~/.local/bin/npm` — ahead of `/usr/bin/npm` in PATH — so it intercepts npm calls from **all** processes: interactive shells, CI, Claude Code, GitHub Copilot, and any other AI coding agent.

## Uninstall

```bash
rm ~/.local/bin/npm
```

## Copilot Skill

This repo also ships as a [Copilot Skill](./SKILL.md) — add it to your Claude Code or Copilot setup and any AI agent can install the quarantine wrapper for you.

## Compatibility

- ✅ Linux (GNU date)
- ✅ macOS (BSD date)
- ⚠️ Bun: no `--before` equivalent — use npm for installs where supply chain safety matters

## License

MIT
