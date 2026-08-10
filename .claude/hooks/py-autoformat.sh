#!/usr/bin/env bash
# PostToolUse(Write|Edit) hook: auto-format the Python file just edited using the
# project's own ruff, so formatting churn never reaches lint/commit. Reads the
# hook payload on stdin. Silent and non-blocking by design — it must never fail a
# turn or impose ruff style on a project that didn't opt into it.
set -u

file="$(jq -r '.tool_input.file_path // empty' 2>/dev/null)"
case "$file" in
  *.py) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

ruff=""
config=""
dir="$(cd "$(dirname "$file")" 2>/dev/null && pwd)" || exit 0
while [ -n "$dir" ] && [ "$dir" != "/" ]; do
  [ -z "$ruff" ] && [ -x "$dir/.venv/bin/ruff" ] && ruff="$dir/.venv/bin/ruff"
  if [ -z "$config" ] && { [ -f "$dir/pyproject.toml" ] || [ -f "$dir/ruff.toml" ] || [ -f "$dir/.ruff.toml" ]; }; then
    config="$dir"
  fi
  dir="$(dirname "$dir")"
done

# No project config means the project never opted into ruff — leave it alone.
[ -z "$config" ] && exit 0
[ -z "$ruff" ] && ruff="$(command -v ruff || true)"
[ -z "$ruff" ] && exit 0

"$ruff" format "$file" >/dev/null 2>&1 || true
"$ruff" check --fix --select I "$file" >/dev/null 2>&1 || true
exit 0
