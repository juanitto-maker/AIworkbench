#!/usr/bin/env bash
# aiwb — AI Workbench orchestrator (Gum TUI if available; plain prompts otherwise)
set -euo pipefail

# ---- locations & env ----
AIWB="${AIWB:-$HOME/storage/shared/0code/0ai-workbench}"
AIWB_CODE_ROOT="${AIWB_CODE_ROOT:-$HOME/storage/shared/0code}"
[ -f "$HOME/.aiwb.env" ] && . "$HOME/.aiwb.env" || true
[ -f ".env" ] && . ./.env || true

# ---- helpers ----
has()  { command -v "$1" >/dev/null 2>&1; }
say()  { printf '%s\n' "$*"; }
err()  { printf 'ERROR: %s\n' "$*" >&2; }

gum_choose() {
  if has gum; then
    gum choose "$@"
  else
    i=0
    for opt in "$@"; do i=$((i+1)); printf '%d) %s\n' "$i" "$opt"; done
    read -r -p "Choose [1-$i]: " n
    case "${n:-}" in
      '')   echo "" ;;
      * )
        i=0
        for opt in "$@"; do
          i=$((i+1))
          if [ "$i" = "$n" ]; then echo "$opt"; return 0; fi
        done
        echo ""
      ;;
    esac
  fi
}

gum_confirm() {
  if has gum; then
    gum confirm "${1:-Proceed?}"
  else
    read -r -p "${1:-Proceed?} [y/N]: " yn
    case "$yn" in y|Y) return 0 ;; *) return 1 ;; esac
  fi
}

gum_input() {
  if has gum; then
    gum input --placeholder "${1:-}"
  else
    read -r -p "${1:-}: " REPLY || true
    printf '%s' "$REPLY"
  fi
}

gum_spin() {
  # $1 title, $2 command string
  if has gum; then
    gum spin --title "${1:-Working...}" -- bash -lc "${2}"
  else
    bash -lc "${2}"
  fi
}

ensure_dirs() { mkdir -p "$AIWB" "$AIWB_CODE_ROOT" "$AIWB/temp"; }

# ---- project / task / prompt ----
get_project() { cat "$AIWB/current.project" 2>/dev/null || true; }
get_task()    { cat "$AIWB/current.task"    2>/dev/null || true; }
set_project() { p="$1"; [ -n "$p" ] || return 1; printf '%s' "$p" > "$AIWB/current.project"; mkdir -p "$AIWB_CODE_ROOT/$p/temp" "$AIWB_CODE_ROOT/$p/out"; }
set_task()    { t="$1"; [ -n "$t" ] || return 1; printf '%s' "$t" > "$AIWB/current.task"; }

prompt_path() {
  p="$(get_project)"; t="$(get_task)"
  [ -n "$t" ] || { echo ""; return 0; }
  if [ -n "$p" ] && [ -f "$AIWB_CODE_ROOT/$p/temp/$t.prompt.md" ]; then
    echo "$AIWB_CODE_ROOT/$p/temp/$t.prompt.md"; return 0
  fi
  if [ -f "$AIWB/temp/$t.prompt.md" ]; then
    echo "$AIWB/temp/$t.prompt.md"; return 0
  fi
  if [ -n "$p" ]; then
    echo "$AIWB_CODE_ROOT/$p/temp/$t.prompt.md"; return 0
  fi
  echo "$AIWB/temp/$t.prompt.md"
}

ensure_project_task() {
  p="$(get_project)"; t="$(get_task)"
  if [ -z "$p" ]; then
    p="$(gum_input 'Project name (e.g., myapp)')" || true
    [ -z "$p" ] && { err "No project"; return 1; }
    set_project "$p"
  fi
  if [ -z "$t" ]; then
    t="$(gum_input 'Task id (e.g., t0001)')" || true
    [ -z "$t" ] && { err "No task"; return 1; }
    set_task "$t"
  fi
}

edit_prompt() {
  ensure_project_task || return 1
  f="$(prompt_path)"
  mkdir -p "$(dirname "$f")"
  if [ ! -f "$f" ]; then
    cat > "$f" <<'TPL'
# Brief
Describe the feature/product clearly.

# Requirements
- List key requirements…

# Deliverables
- List outputs/code/artifacts…

# Notes
- Anything else…
TPL
  fi
  if   has xed;   then xed   "$f"
  elif has code;  then code  "$f"
  elif has micro; then micro "$f"
  elif has nano;  then nano  "$f"
  else
    say "Edit this file with your editor:"
    say "$f"
  fi
}

choose_model() {
  default="${AIWB_DEFAULT_MODEL:-gemini}"
  c="$(gum_choose gemini claude)"
  [ -z "$c" ] && printf '%s\n' "$default" || printf '%s\n' "$c"
}

choose_tier() {
  c="$(gum_choose Abort Basic Medium Best)"
  case "$c" in
    ""|Abort)  echo "" ;;
    Basic)     echo "basic" ;;
    Medium)    echo "medium" ;;
    Best)      echo "top" ;;
  esac
}

# ---- actions ----
do_estimate() {
  ensure_project_task || return 1
  f="$(prompt_path)"
  [ -f "$f" ] || { err "No prompt file yet. Use 'Edit Prompt'."; return 1; }

  model="$(choose_model)"
  tier="$(choose_tier)"
  [ -z "$tier" ] && { say "Aborted."; return 0; }

  if [ "$model" = "gemini" ]; then
    gum_spin "Estimating (Gemini)" "gpre.sh --tier '$tier'"
    if gum_confirm "Generate now with '$tier'?"; then
      gum_spin "Generating (Gemini)" "ggo.sh --tier '$tier'"
    fi
  else
    gum_spin "Estimating (Claude)" "cpre.sh --tier '$tier'"
    if gum_confirm "Generate now with '$tier'?"; then
      gum_spin "Generating (Claude)" "cgo.sh --tier '$tier'"
    fi
  fi
}

do_generate() {
  ensure_project_task || return 1
  model="$(choose_model)"
  tier="$(choose_tier)"
  [ -z "$tier" ] && { say "Aborted."; return 0; }
  if [ "$model" = "gemini" ]; then
    gum_spin "Generating (Gemini)" "ggo.sh --tier '$tier'"
  else
    gum_spin "Generating (Claude)" "cgo.sh --tier '$tier'"
  fi
}

do_preview() {
  ensure_project_task || return 1
  p="$(get_project)"; t="$(get_task)"
  out2="$AIWB_CODE_ROOT/$p/out/$t/index.html"
  out1="$AIWB_CODE_ROOT/$p/out/index.html"
  page=""
  [ -f "$out2" ] && page="$out2"
  [ -z "$page" ] && [ -f "$out1" ] && page="$out1"
  if [ -z "$page" ]; then
    say "No index.html found. Looked for:"
    say "  $out2"
    say "  $out1"
    return 1
  fi
  say "Preview: $page"
  if   has termux-open; then termux-open "$page" || true
  elif has xdg-open;   then xdg-open   "$page" || true
  elif has open;       then open       "$page" || true
  fi
}

do_chat() {
  ensure_project_task || return 1
  model="$(choose_model)"
  say "Chat started (model: $model). Type /quit to exit."
  while true; do
    msg="$(gum_input 'You')" || true
    [ "$msg" = "/quit" ] && break
    [ -z "$msg" ] && continue
    if [ "$model" = "gemini" ]; then
      ggo.sh "$msg" --raw
    else
      cgo.sh "$msg" --raw
    fi
  done
}

do_project_task() {
  p="$(gum_input 'Project name')" || true
  [ -z "$p" ] && { say "No change."; return 0; }
  t="$(gum_input 'Task id (e.g., t0001)')" || true
  [ -z "$t" ] && { say "No change."; return 0; }
  set_project "$p"
  set_task "$t"
  say "Current: project=$p  task=$t"
}

main_menu() {
  while true; do
    p="$(get_project)"; t="$(get_task)"
    if has gum; then
      say "Project: ${p:-<none>}    Task: ${t:-<none>}"
      choice="$(gum_choose Estimate Generate Preview Chat 'Project/Task' 'Edit Prompt' Exit)"
    else
      say "AI Workbench — Project: ${p:-<none>}  Task: ${t:-<none>}"
      say "1) Estimate"
      say "2) Generate"
      say "3) Preview"
      say "4) Chat"
      say "5) Project/Task"
      say "6) Edit Prompt"
      say "7) Exit"
      read -r -p "Choose: " n
      case "${n:-}" in
        1) choice="Estimate" ;;
        2) choice="Generate" ;;
        3) choice="Preview" ;;
        4) choice="Chat" ;;
        5) choice="Project/Task" ;;
        6) choice="Edit Prompt" ;;
        *) choice="Exit" ;;
      esac
    fi

    case "${choice:-Exit}" in
      Estimate)       do_estimate ;;
      Generate)       do_generate ;;
      Preview)        do_preview ;;
      Chat)           do_chat ;;
      'Project/Task') do_project_task ;;
      'Edit Prompt')  edit_prompt ;;
      *) break ;;
    esac
  done
}

# ---- entry ----
ensure_dirs
main_menu