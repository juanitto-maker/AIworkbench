#!/data/data/com.termux/files/usr/bin/bash
# ===== AI HYBRID HELPERS =====
# After saving:  source ~/.bashrc

# Root of the shared workbench
export AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"

# ---------- 1) settask <TID> ----------
# Scaffold minimal files in the *current repo* and set active task in workbench.
settask() {
  local T="$1"
  if [ -z "$T" ]; then echo "Usage: settask T123"; return 1; fi

  mkdir -p ./tasks ./temp ./decisions ./todo ./drafts ./history

  [ ! -f "./tasks/$T.md" ] && cat > "./tasks/$T.md" <<EOF
# $T: Short Title

## Goal
(One short paragraph)

## Scope (what changes)
-

## Constraints (what must not change)
-

## Acceptance
-
EOF

  [ ! -f "./temp/$T.prompt.md" ] && touch "./temp/$T.prompt.md"
  echo "NEW" > "./temp/$T.status.txt"

  mkdir -p "$AIWB"
  echo "$T" > "$AIWB/current.task"

  echo "✅ Task $T scaffolded in repo: $(pwd)"
  echo "   - tasks/$T.md"
  echo "   - temp/$T.prompt.md"
  echo "   - temp/$T.status.txt (NEW)"
  echo "   Active task set in $AIWB/current.task"
}

# ---------- 2) bridgeg <TID> ----------
# Copy Gemini output from workbench → repo draft for Claude to review.
bridgeg() {
  local T="$1"
  if [ -z "$T" ]; then echo "Usage: bridgeg T123"; return 1; fi
  mkdir -p ./temp
  cp "$AIWB/gemini-out/$T.output.md" "./temp/$T.draft.md" 2>/dev/null \
    && echo "✅ Copied output → temp/$T.draft.md" \
    || echo "❌ Missing: $AIWB/gemini-out/$T.output.md"
}

# ---------- 3) bridgec <TID> ----------
# Turn Claude’s review (repo) into a *new* Gemini prompt in workbench.
bridgec() {
  local T="$1"
  if [ -z "$T" ]; then echo "Usage: bridgec T123"; return 1; fi
  local REV="./temp/$T.review.md"
  local OUT="$AIWB/gemini-prompts/$T.prompt.md"

  if [ ! -f "$REV" ]; then echo "❌ Missing: $REV"; return 1; fi

  mkdir -p "$AIWB/gemini-prompts"
  {
    echo "TASK $T — Revise draft per verifier feedback"
    echo
    echo "You are revising the existing draft for task $T."
    echo "- Apply ONLY the fixes listed below."
    echo "- Keep scope limited to tasks/$T.md."
    echo "- Preserve behavior/UX; minimal diffs."
    echo "- Output the updated plan (≤600 words) in the same structure."
    echo
    echo "=== VERIFIER REVIEW (Claude) START ==="
    cat "$REV"
    echo "=== VERIFIER REVIEW END ==="
  } > "$OUT"

  echo "✅ New Gemini prompt written: $OUT"
  echo "   Run: gemini-runner.sh $T"
}

# ---------- 4) status [TID] ----------
status() {
  local T="$1"
  if [ -z "$T" ] && [ -f "$AIWB/current.task" ]; then T="$(cat "$AIWB/current.task")"; fi
  if [ -z "$T" ]; then echo "Usage: status T123  (or set $AIWB/current.task)"; return 1; fi
  if [ -f "./temp/$T.status.txt" ]; then
    echo "📟 Repo: $(basename "$(pwd)")"
    echo "Task $T → $(cat "./temp/$T.status.txt")"
  else
    echo "ℹ️ No ./temp/$T.status.txt in this repo."
  fi
}

# ---------- 5) tasktree ----------
tasktree() {
  echo "🗂  $(pwd)"
  for f in ./tasks/*.md; do
    [ -e "$f" ] || continue
    T="$(basename "$f" .md)"
    S="(no status)"
    [ -f "./temp/$T.status.txt" ] && S="$(cat "./temp/$T.status.txt")"
    echo " - $T  →  $S"
  done
}

# ---------- 6) flushdrafts <TID> ----------
flushdrafts() {
  local T="$1"
  if [ -z "$T" ]; then echo "Usage: flushdrafts T123"; return 1; fi

  echo "🧹 Flushing task: $T"

  # Repo files
  rm -f "./temp/$T.draft.md" "./temp/$T.review.md" "./temp/$T.status.txt" \
        "./drafts/$T-draft-v1.md"
  echo " - Cleared repo: ./temp/, ./drafts/"

  # Workbench files
  rm -f "$AIWB/gemini-out/$T.output.md" \
        "$AIWB/runner-logs/$T.log" \
        "$AIWB/gemini-prompts/$T.prompt.md"
  echo " - Cleared AI workbench: gemini-out, logs, prompts"
}

# ---------- 7) bridgeprompt <TID> ----------
# Copy local prompt → Gemini input folder
bridgeprompt() {
  local T="$1"
  if [ -z "$T" ]; then echo "Usage: bridgeprompt T123"; return 1; fi
  local IN="./temp/$T.prompt.md"
  local OUT="$AIWB/gemini-prompts/$T.prompt.md"
  [ ! -f "$IN" ] && { echo "❌ Missing: $IN"; return 1; }
  mkdir -p "$AIWB/gemini-prompts"
  cp "$IN" "$OUT" && echo "✅ Prompt copied to Gemini workbench: $OUT"
}