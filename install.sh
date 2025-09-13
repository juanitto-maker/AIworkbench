#!/usr/bin/env bash
# install.sh — Universal installer for AIworkbench (Linux/macOS/Termux)
# - Detects platform & package manager
# - Installs deps: bash jq curl git fzf gum sed awk tar (and age for key vault)
# - Creates workspace at ~/.aiwb/
# - Clones/updates repo at ~/.aiwb/aiworkbench/
# - Installs scripts to ~/.local/bin (or ~/bin fallback) via binpush.sh
# - Ensures PATH contains install dir for current shell
# - Idempotent; safe to re-run

set -euo pipefail

# ------------------------------- CONFIG ---------------------------------------
REPO_URL_DEFAULT="https://github.com/juanitto-maker/AIworkbench.git"
REPO_URL="${AIWB_REPO_URL:-$REPO_URL_DEFAULT}"
AIWB_HOME="${HOME}/.aiwb"
AIWB_REPO_DIR="${AIWB_HOME}/aiworkbench"
WORKSPACE_DIR="${AIWB_HOME}/workspace"
DEST_BIN_DEFAULT="${HOME}/.local/bin"
DEST_BIN_FALLBACK="${HOME}/bin"
NEEDED_CMDS=(bash jq curl git fzf sed awk tar)
OPT_CMDS=(gum age)

# Pin a known-good gum if we must fetch manually (used as last resort)
GUM_VERSION="${AIWB_GUM_VERSION:-0.13.0}"

# ------------------------------ UTILITIES -------------------------------------
msg()  { printf "\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!! \033[0m%s\n" "$*" >&2; }
err()  { printf "\033[1;31mEE \033[0m%s\n" "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

is_termux() { [[ "${PREFIX:-}" == *com.termux* ]] || [[ "${OSTYPE:-}" == "linux-android"* ]]; }

detect_pm() {
  if is_termux; then echo "pkg" && return; fi
  if have apt-get; then echo "apt"; return; fi
  if have pacman;  then echo "pacman"; return; fi
  if have dnf;     then echo "dnf"; return; fi
  if have zypper;  then echo "zypper"; return; fi
  if have apk;     then echo "apk"; return; fi
  if have brew;    then echo "brew"; return; fi
  echo "none"
}

ensure_dir() { mkdir -p "$1"; }

ensure_path_export() {
  local bindir="$1"
  local shell_rc
  # Choose an rc to update for current shell
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    shell_rc="${HOME}/.zshrc"
  else
    shell_rc="${HOME}/.bashrc"
  fi
  if ! printf "%s" "$PATH" | tr ':' '\n' | grep -qx "$bindir"; then
    msg "Adding ${bindir} to PATH in ${shell_rc}"
    {
      echo ""
      echo "# AIworkbench installer: add local bin to PATH"
      echo "export PATH=\"${bindir}:\$PATH\""
    } >> "${shell_rc}"
    # Update current session where possible
    export PATH="${bindir}:${PATH}"
  fi
}

arch_triplet() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64)  arch="x86_64" ;;
    aarch64|arm64) arch="arm64"  ;;
    armv7l)        arch="armv7"  ;;
    *)             arch="$(uname -m)" ;;
  esac
  echo "${os}-${arch}"
}

fetch_gum_to() {
  # Attempt package-manager install first; fallback to GitHub release
  local pm="$1" dest_bin="$2"
  if have gum; then return 0; fi

  case "$pm" in
    pkg)    msg "Installing gum via pkg"; pkg update -y || true; pkg install -y gum && return 0 || true ;;
    apt)    msg "Installing gum via apt"; sudo apt-get update -y || true; sudo apt-get install -y gum && return 0 || true ;;
    pacman) msg "Installing gum via pacman"; sudo pacman -Syu --noconfirm gum && return 0 || true ;;
    dnf)    msg "Installing gum via dnf"; sudo dnf install -y gum && return 0 || true ;;
    zypper) msg "Installing gum via zypper"; sudo zypper install -y gum && return 0 || true ;;
    apk)    msg "Installing gum via apk"; sudo apk add --no-cache gum && return 0 || true ;;
    brew)   msg "Installing gum via brew"; brew install gum && return 0 || true ;;
  esac

  # Fallback manual download
  local triplet; triplet="$(arch_triplet)"
  local url=""
  # Map common triplets to gum release assets
  case "$triplet" in
    linux-x86_64) url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_Linux_x86_64.tar.gz" ;;
    linux-arm64)  url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_Linux_arm64.tar.gz" ;;
    linux-armv7)  url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_Linux_armv7.tar.gz" ;;
    darwin-arm64) url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_macOS_arm64.tar.gz" ;;
    darwin-x86_64)url="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_macOS_x86_64.tar.gz" ;;
    *) url="" ;;
  esac

  if [[ -z "$url" ]]; then
    warn "Unknown platform ($triplet) for gum; please install gum manually."
    return 1
  fi

  msg "Downloading gum ${GUM_VERSION} for ${triplet}"
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  ( cd "$tmp" && curl -fsSL "$url" -o gum.tgz && tar -xzf gum.tgz )
  if [[ -f "${tmp}/gum" ]]; then
    install -m 0755 "${tmp}/gum" "${dest_bin}/gum"
    msg "Installed gum to ${dest_bin}/gum"
    return 0
  fi
  warn "gum fallback install failed; continue without gum."
  return 1
}

install_pkgs() {
  local pm="$1"
  local pkgs=("${@:2}")
  case "$pm" in
    pkg)    pkg update -y || true; pkg install -y "${pkgs[@]}" ;;
    apt)    sudo apt-get update -y || true; sudo apt-get install -y "${pkgs[@]}" ;;
    pacman) sudo pacman -Syu --noconfirm "${pkgs[@]}" ;;
    dnf)    sudo dnf install -y "${pkgs[@]}" ;;
    zypper) sudo zypper install -y "${pkgs[@]}" ;;
    apk)    sudo apk add --no-cache "${pkgs[@]}" ;;
    brew)   brew install "${pkgs[@]}" ;;
    none)   warn "No package manager detected. Please install: ${pkgs[*]}" ;;
  esac
}

# ------------------------------ MAIN FLOW -------------------------------------
msg "Detecting platform & package manager…"
PM="$(detect_pm)"
msg "Package manager: ${PM}"

# Choose destination bin directory
DEST_BIN="$DEST_BIN_DEFAULT"
if [[ ! -d "$DEST_BIN" ]]; then
  ensure_dir "$DEST_BIN" || true
  if [[ ! -d "$DEST_BIN" ]]; then
    DEST_BIN="$DEST_BIN_FALLBACK"
    ensure_dir "$DEST_BIN"
  fi
fi
msg "Binary install dir: ${DEST_BIN}"

# Ensure core deps
msg "Ensuring core dependencies: ${NEEDED_CMDS[*]}"
install_pkgs "$PM" "${NEEDED_CMDS[@]}" || true

# Optional deps (age for encrypted key vault)
msg "Ensuring optional dependencies: ${OPT_CMDS[*]}"
install_pkgs "$PM" "${OPT_CMDS[@]}" || true

# Special handling for gum (some distros lack it)
if ! have gum; then
  fetch_gum_to "$PM" "$DEST_BIN" || warn "gum not installed; TUI will be simplified until you install gum."
fi

# Create workspace
msg "Preparing AIWB workspace at ${AIWB_HOME}"
ensure_dir "${WORKSPACE_DIR}/projects"
ensure_dir "${WORKSPACE_DIR}/tasks"
ensure_dir "${WORKSPACE_DIR}/snapshots"
ensure_dir "${WORKSPACE_DIR}/logs"

# Clone or update repo
if [[ -d "${AIWB_REPO_DIR}/.git" ]]; then
  msg "Updating existing repo at ${AIWB_REPO_DIR}"
  git -C "${AIWB_REPO_DIR}" fetch --all --prune
  git -C "${AIWB_REPO_DIR}" pull --ff-only || warn "git pull failed; continuing with current checkout."
else
  msg "Cloning repo → ${AIWB_REPO_DIR}"
  ensure_dir "${AIWB_REPO_DIR%/*}"
  git clone --depth 1 "${REPO_URL}" "${AIWB_REPO_DIR}"
fi

# Run binpush if present; else fallback copy
BINPUSH="${AIWB_REPO_DIR}/bin-edit/binpush.sh"
if [[ -x "$BINPUSH" ]]; then
  msg "Installing runners via binpush.sh → ${DEST_BIN}"
  # Make sure binpush itself runs with the local interpreter
  bash "$BINPUSH" || {
    warn "binpush failed; falling back to direct copy."
    cp -f "${AIWB_REPO_DIR}/bin-edit/"*.sh "${DEST_BIN}/" || true
    chmod +x "${DEST_BIN}/"*.sh 2>/dev/null || true
  }
else
  warn "binpush.sh not found or not executable; copying scripts directly."
  cp -f "${AIWB_REPO_DIR}/bin-edit/"*.sh "${DEST_BIN}/" || true
  chmod +x "${DEST_BIN}/"*.sh 2>/dev/null || true
fi

# Ensure PATH
ensure_path_export "${DEST_BIN}"

# Bootstrap config.json if missing
CONFIG_JSON="${AIWB_HOME}/config.json"
if [[ ! -f "$CONFIG_JSON" ]]; then
  msg "Creating default config at ${CONFIG_JSON}"
  cat > "$CONFIG_JSON" <<'JSON'
{
  "workspace": {
    "root": "~/.aiwb/workspace",
    "projects": "~/.aiwb/workspace/projects",
    "tasks": "~/.aiwb/workspace/tasks",
    "snapshots": "~/.aiwb/workspace/snapshots",
    "logs": "~/.aiwb/workspace/logs"
  },
  "models": {
    "default_provider": "gemini",
    "gemini_default": "flash-1.5",
    "claude_default": "sonnet-3.5"
  },
  "ui": {
    "chat_first": true,
    "double_check_gate": true
  }
}
JSON
fi

# Short success summary
echo
msg "Installation complete."
echo " Repo:       ${AIWB_REPO_DIR}"
echo " Workspace:  ${WORKSPACE_DIR}"
echo " Binaries:   ${DEST_BIN} (ensure your shell has it in PATH)"
echo
echo "Try:   aiwb"
echo "If gum wasn't available, install it later for the full TUI experience."
