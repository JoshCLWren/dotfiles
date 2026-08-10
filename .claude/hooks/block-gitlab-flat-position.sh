#!/usr/bin/env bash
# PreToolUse/Bash guard.
#
# `glab api -f "position[new_path]=..."` serializes the bracket keys as literal JSON
# keys. GitLab does not recognize them, drops the position, and returns 201 with the
# comment on the MR Overview tab instead of anchored to the diff. Nothing in the
# response signals the failure, so this mistake is invisible without a guard.
set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')

# Require an actual API invocation, not just prose. Without this, a `git commit -m`
# whose message merely describes the bug trips the guard.
case "$cmd" in
  *glab*|*curl*)
    case "$cmd" in
      *merge_requests*) ;;
      *) exit 0 ;;
    esac
    case "$cmd" in
      *'position['*)
        cat >&2 <<'MSG'
BLOCKED: bracketed `position[...]` params do not work for GitLab MR comments.

glab flattens them into literal JSON keys, GitLab ignores the position, and the
comment silently lands on the Overview tab with a 201 that looks like success.
(`glab api --input` also fails: HTTP 415, no content-type.)

Use the script instead, which resolves diff refs, derives the old_line/new_line
pairing, and verifies each note actually anchored:

  python3 ~/.claude/skills/gitlab-mr-inline-comments/scripts/post_inline_comment.py \
    --mr <iid> --comments comments.json --dry-run

Details, including the added/removed/context line rules:
  ~/.claude/skills/gitlab-mr-inline-comments/SKILL.md

Posting by hand requires curl with an explicit `Content-Type: application/json`
and a genuinely nested "position" object.
MSG
        exit 2
        ;;
    esac
    ;;
esac

exit 0
