#!/usr/bin/env bash
# PermissionRequest hook — auto-approves safe tool calls for frontend setup.
# Falls through to normal permission prompt for anything not explicitly allowed.

set -euo pipefail

INPUT=$(cat)

# Parse JSON fields from stdin. Try node first, fall back to jq.
parse_field() {
  local field="$1"
  if command -v node &>/dev/null; then
    echo "$INPUT" | node -e "
      let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
        try {
          const val = '$field'.split('.').reduce((o,k)=>o&&o[k], JSON.parse(d));
          process.stdout.write(String(val||''));
        } catch(e) { process.exit(1); }
      });
    " 2>/dev/null
  elif command -v jq &>/dev/null; then
    echo "$INPUT" | jq -r ".$field // empty" 2>/dev/null
  else
    return 1
  fi
}

TOOL=$(parse_field "tool_name") || exit 1
[ -z "$TOOL" ] && exit 1

approve() {
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow","message":"auto-approved by frontend-setup plugin"}}}
EOF
  exit 0
}

# --- Read-only tools: always approve ---
case "$TOOL" in
  Read|Glob|Grep)
    approve
    ;;
esac

# --- File writes: approve within BTNet repo ---
case "$TOOL" in
  Write|Edit)
    FILE_PATH=$(parse_field "tool_input.file_path") || true
    if [ -n "$FILE_PATH" ] && echo "$FILE_PATH" | grep -q "BTNet"; then
      approve
    fi
    exit 1
    ;;
esac

# --- Bash commands ---
if [ "$TOOL" != "Bash" ]; then
  exit 1
fi

COMMAND=$(parse_field "tool_input.command") || exit 1
[ -z "$COMMAND" ] && exit 1

CMD_FIRST=$(echo "$COMMAND" | sed 's/^[[:space:]]*//' | cut -d' ' -f1)

case "$CMD_FIRST" in
  # OS detection and info
  uname|sw_vers|cat|echo|printf|test|"[")
    ;;
  # File operations
  ls|pwd|cd|mkdir|cp|touch|head|tail|wc)
    ;;
  # Prerequisite checks and installs
  xcode-select|brew|fnm|node|npm|npx|pnpm|corepack)
    ;;
  # Git operations
  git)
    ;;
  # System utilities
  which|command|type|env|printenv)
    ;;
  # Shell config
  source|.)
    ;;
  # Package installation (Mac)
  sudo)
    SUDO_CMD=$(echo "$COMMAND" | awk '{print $2}')
    case "$SUDO_CMD" in
      pnpm|corepack|chown)
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  # Network utilities
  curl|wget)
    ;;
  bash)
    # Block bare "bash" with no arguments
    if [ "$COMMAND" = "bash" ]; then
      exit 1
    fi
    ;;
  rm)
    # Only approve rm for node_modules cleanup
    if echo "$COMMAND" | grep -qE '^rm -rf node_modules'; then
      approve
    fi
    exit 1
    ;;
  *)
    exit 1
    ;;
esac

approve
