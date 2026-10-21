#!/usr/bin/env bash
# SessionStart hook: fetch origin and tell the model when the checkout is stale.
# Stale local main caused review diffs to include merged commits, and an old
# checkout produced wrong facts in docs. Advisory only; never fails the session.
set -u

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
git remote get-url origin >/dev/null 2>&1 || exit 0

gtimeout 15 git fetch origin --quiet >/dev/null 2>&1 || timeout 15 git fetch origin --quiet >/dev/null 2>&1 || true

default="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
[ -n "$default" ] || default="origin/main"
git rev-parse --verify --quiet "$default" >/dev/null || exit 0

repo="$(basename "$(git rev-parse --show-toplevel)")"
branch="$(git rev-parse --abbrev-ref HEAD)"
behind="$(git rev-list --count "HEAD..$default" 2>/dev/null || echo 0)"
local_main="${default#origin/}"
main_behind="$(git rev-list --count "$local_main..$default" 2>/dev/null || echo 0)"
last="$(git log -1 --format='%cr' "$default" 2>/dev/null)"

notes=""
[ "$behind" -gt 0 ] && notes="$notes
- Branch $branch is $behind commits behind $default. Code you read here may be out of date."
[ "$main_behind" -gt 0 ] && notes="$notes
- Local $local_main is $main_behind commits behind $default. Diff against \$(git merge-base $default HEAD), never local $local_main."
[ -n "$notes" ] || exit 0

jq -nc --arg ctx "Freshness check for repo $repo (last commit on $default: $last):$notes" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}' 2>/dev/null || true
exit 0
