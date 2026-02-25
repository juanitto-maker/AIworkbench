#!/bin/bash
# .claude/hooks/session-start.sh
# Session-start hook for Claude Code on the web.
# Installs AIWB runtime and dev dependencies (bats, shellcheck, fzf, gum).
# Idempotent — safe to re-run on session resume/clear.

set -euo pipefail

# Only run in remote Claude Code sessions
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# ── Charm apt repo (needed for gum) ──────────────────────────────────────────
if ! command -v gum >/dev/null 2>&1; then
  echo "==> Adding Charm apt repo for gum..."
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://repo.charm.sh/apt/gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
  echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
    > /etc/apt/sources.list.d/charm.list
fi

# ── Determine which packages actually need installing ─────────────────────────
MISSING=()
command -v bats       >/dev/null 2>&1 || MISSING+=(bats)
command -v shellcheck >/dev/null 2>&1 || MISSING+=(shellcheck)
command -v fzf        >/dev/null 2>&1 || MISSING+=(fzf)
command -v gum        >/dev/null 2>&1 || MISSING+=(gum)

if [ ${#MISSING[@]} -eq 0 ]; then
  echo "==> All AIWB dependencies already installed."
  exit 0
fi

echo "==> Installing missing packages: ${MISSING[*]}"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  "${MISSING[@]}"

# ── Verify ────────────────────────────────────────────────────────────────────
echo "==> Verifying installed tools:"
bats       --version
shellcheck --version | head -1
fzf        --version
gum        --version

echo "==> AIWB session-start hook complete."
