#!/usr/bin/env python3
import json
import subprocess

HOOK = "/Users/joshwren/dotfiles/.claude/hooks/block-gitlab-flat-position.sh"
BRACKET = "position" + "["

CASES = [
    (2, "glab flat position",
     'glab api --method POST projects/:id/merge_requests/4711/discussions -f "%snew_path]=a.ts"' % BRACKET),
    (2, "curl flat position",
     'curl -X POST https://x/merge_requests/1/discussions -d "%snew_line]=5"' % BRACKET),
    (0, "git commit prose mentioning both",
     'git commit -F - <<EOF\nblocks %s...] on merge_requests endpoints\nEOF' % BRACKET),
    (0, "normal glab read",
     "glab api projects/:id/merge_requests/4711/discussions"),
    (0, "the sanctioned script",
     "python3 ~/.claude/skills/gitlab-mr-inline-comments/scripts/post_inline_comment.py --mr 4711"),
    (0, "curl with nested json body",
     'curl -X POST https://x/merge_requests/1/discussions -H "Content-Type: application/json" --data-binary @p.json'),
    (0, "unrelated bracket usage",
     "echo %s0]" % BRACKET),
    (0, "glab without merge_requests",
     'glab api projects/:id/issues -f "%sx]=1"' % BRACKET),
]

failed = 0
for want, name, cmd in CASES:
    p = subprocess.run([HOOK], input=json.dumps({"tool_input": {"command": cmd}}),
                       capture_output=True, text=True)
    ok = p.returncode == want
    failed += not ok
    print(f"{'PASS' if ok else 'FAIL'}  want={want} got={p.returncode}  {name}")

print("\nall good" if not failed else f"\n{failed} case(s) wrong")
raise SystemExit(1 if failed else 0)
