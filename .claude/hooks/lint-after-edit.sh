#!/usr/bin/env bash
# PostToolUse(Write|Edit|MultiEdit) hook: language-agnostic "lint after edit".
#
# Formats the file just edited with the project's own tooling (auto-fix, silent)
# and surfaces any remaining LINT findings back to the model as additionalContext
# so they are fixed before they reach CI — the same class of failure that breaks
# the pipeline (e.g. a golangci-lint rule). Companion to py-autoformat.sh, which
# owns Python formatting; this script never re-formats .py.
#
# Philosophy (matches py-autoformat.sh): opt-in per project — a tool only runs
# when its binary/config is actually present — and it must NEVER fail the turn.
# It exits 0 always; findings are advisory context, not a block.
set -u

payload="$(cat)"
file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

# Nearest ancestor with a project marker = root for tool/config lookup.
root="$(cd "$(dirname "$file")" 2>/dev/null && pwd)" || exit 0
d="$root"
while [ -n "$d" ] && [ "$d" != "/" ]; do
  if [ -e "$d/.git" ] || [ -f "$d/go.mod" ] || [ -f "$d/package.json" ] || [ -f "$d/pyproject.toml" ]; then
    root="$d"
    break
  fi
  d="$(dirname "$d")"
done

# Surface lint output to the model (non-blocking). Single JSON object on stdout.
emit() {
  [ -n "$1" ] || return 0
  jq -nc --arg ctx "lint-after-edit flagged $file — fix these before commit/push:
$1" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$ctx}}' 2>/dev/null || true
}

case "${file##*.}" in
  go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$file" >/dev/null 2>&1 || true
    gci="$root/bin/golangci-lint"
    [ -x "$gci" ] || gci="$(command -v golangci-lint || true)"
    if [ -n "$gci" ] && [ -f "$root/go.mod" ]; then
      pkg="./$(dirname "${file#"$root"/}")"
      out="$(cd "$root" && "$gci" run --timeout 60s "$pkg" 2>&1)"
      [ $? -ne 0 ] && emit "$out"
    fi
    ;;
  py)
    # Formatting is handled by py-autoformat.sh; here we only surface lint findings.
    ruff="$root/.venv/bin/ruff"
    [ -x "$ruff" ] || ruff="$(command -v ruff || true)"
    if [ -n "$ruff" ] && { [ -f "$root/pyproject.toml" ] || [ -f "$root/ruff.toml" ] || [ -f "$root/.ruff.toml" ]; }; then
      out="$("$ruff" check "$file" 2>&1)"
      [ $? -ne 0 ] && emit "$out"
    fi
    ;;
  js | jsx | ts | tsx | mjs | cjs)
    pretti="$root/node_modules/.bin/prettier"
    [ -x "$pretti" ] && "$pretti" --write "$file" >/dev/null 2>&1 || true
    esl="$root/node_modules/.bin/eslint"
    if [ -x "$esl" ]; then
      out="$(cd "$root" && "$esl" "$file" 2>&1)"
      [ $? -ne 0 ] && emit "$out"
    fi
    ;;
  rs)
    command -v rustfmt >/dev/null 2>&1 && rustfmt "$file" >/dev/null 2>&1 || true
    ;;
  *)
    exit 0
    ;;
esac
exit 0
