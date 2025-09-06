#!/data/data/com.termux/files/usr/bin/bash
# Shared knobs + cost/confirm preflight

# You can override these in ~/.bashrc
export MAX_OUT_TOKENS_DEFAULT="${MAX_OUT_TOKENS_DEFAULT:-8000}"
export CONFIRM="${CONFIRM:-1}"

preflight_cost_confirm() {
  local model="$1" prompt="$2" out_tokens="${3:-$MAX_OUT_TOKENS_DEFAULT}"
  local line
  line=$(ai-cost.sh "$model" "$prompt" "$out_tokens")
  echo "💵 Cost preview: $line"
  if [ "${CONFIRM:-1}" = "0" ]; then return 0; fi
  read -rp "Proceed? [y/N] " yn
  case "$yn" in y|Y) return 0 ;; *) echo "❎ Cancelled."; return 1 ;; esac
}