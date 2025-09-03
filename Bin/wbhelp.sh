#!/data/data/com.termux/files/usr/bin/bash
cat <<'EOF'
⭐ Workbench Commands (no aliases)

Core:
  ai-buildprompt.sh  <TID>   Build prompt from ./temp/<TID>.* into gemini-prompts/<TID>.prompt.md
  ai-preflight.sh    <TID>   Show model, token limits & confirmation
  gemini-runner.sh   <TID>   Run Gemini with ./temp/<TID>.prompt.md
  claude-runner.sh   <TID>   Run Claude review (uses ANTHROPIC_API_KEY)
  ai-prev.sh                  Start local preview server (http-server -p 8080)
  ai-clean.sh                 Remove .bak files & empty dirs
  ai-snap.sh         <TID>   Snapshot temp/ + drafts/ → history/<TID>/<timestamp>/

Uploads:
  uin.sh                      Pick a file and copy into uploads/
  uls.sh                      List uploads/
  uclear.sh [opts]            Clear uploads safely (-a, -o DAYS, -k KEEP, -y)

Utils:
  envkeys.sh [--edit]         Show or edit ~/.aiwb.env
  keys-setup.sh               Create & source ~/.aiwb.env, set defaults
  binpush.sh                  Copy bin-edit/*.sh → ~/bin and chmod +x
  paths.sh                    Show PATH and key directories
  wbhelp.sh                   This help

Tips:
  • After editing scripts in bin-edit/: run  binpush.sh
  • Ensure your keys in ~/.aiwb.env, then:   source ~/.aiwb.env
  • Repo path defaults to: $HOME/storage/shared/0code/0ai-workbench
EOF